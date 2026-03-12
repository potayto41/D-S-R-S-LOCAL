library(shiny)
library(bslib)
library(jsonlite)

# Helper to optionally wrap outputs with spinner if shinycssloaders is available.
with_optional_spinner <- function(ui_element) {
  if (requireNamespace("shinycssloaders", quietly = TRUE)) {
    shinycssloaders::withSpinner(ui_element)
  } else {
    ui_element
  }
}

ui <- page_sidebar(
  # ---- Global theme: lightweight modern styling (Render free-tier safe) ----
  theme = bs_theme(bootswatch = "flatly", base_font = font_google("Inter")),
  title = "Dynamic System Risk Simulator - Phase H4",

  # ---- Sidebar: upload + controls + filters ----
  sidebar = sidebar(
    width = 330,

    card(
      card_header("Data Upload"),
      fileInput("file1", "Upload CSV", accept = c(".csv"))
    ),

    card(
      card_header("User Inputs"),
      textInput("name", "Enter your name:"),
      sliderInput("num", "Select a number:", min = 1, max = 100, value = 50),
      actionButton("go", "Submit", class = "btn-primary"),
      br(), br(),
      textOutput("message")
    ),

    card(
      card_header("Visualization Controls"),
      selectInput("xcol", "X-axis column", choices = NULL),
      selectInput("ycol", "Y-axis column", choices = NULL)
    ),

    card(
      card_header("Filtering"),
      uiOutput("x_filter_ui")
    ),

    card(
      card_header("Forecasting Controls"),
      selectInput("forecast_target", "Select target variable for forecasting", choices = NULL),
      sliderInput("forecast_periods", "Forecast periods ahead", min = 5, max = 30, value = 10, step = 1),
      actionButton("run_forecast", "Generate Forecast", class = "btn-success")
    ),

    card(
      card_header("Dashboard Builder"),
      selectInput("dashboard_component_type", "Add Component Type", 
                  choices = c("Chart", "KPI Card", "Table", "AI Insight")),
      textInput("dashboard_component_name", "Component Name", placeholder = "e.g., Score Trend"),
      actionButton("add_dashboard_component", "Add to Dashboard", class = "btn-info"),
      br(), br(),
      selectInput("saved_dashboards", "Load Dashboard", choices = NULL),
      actionButton("load_dashboard_btn", "Load", class = "btn-secondary"),
      actionButton("save_dashboard_btn", "Save Current", class = "btn-warning"),
      textInput("dashboard_name", "Dashboard Name", placeholder = "My Dashboard"),
      actionButton("delete_dashboard_btn", "Delete Selected", class = "btn-danger")
    )
  ),

  # ---- Main panel: Analytics vs Dashboard tabs ----
  navset_tab(
    title = "Analytics & Dashboards",

    # ---- TAB 1: ANALYTICS (Original View) ----
    nav_panel(
      "Analytics",
      layout_column_wrap(
        width = 1,

        card(
          full_screen = TRUE,
          card_header("Visualization"),
          with_optional_spinner(plotOutput("dataPlot", height = "420px")),
          card_footer(
            "Legend: color = cluster, black ring = z-score anomaly, red/orange/purple overlays = clickable AI highlights, green line = regression."
          )
        ),

        card(
          card_header("Dataset Profile"),
          tableOutput("datasetProfile"),
          htmlOutput("datasetProfileText")
        ),

        layout_columns(
          col_widths = c(6, 6),
          card(
            card_header("Forecast Visualization"),
            with_optional_spinner(plotOutput("forecastPlot", height = "400px"))
          ),
          card(
            card_header("Forecast Summary"),
            tableOutput("forecastTable"),
            htmlOutput("forecastSummary")
          )
        ),

        layout_columns(
          col_widths = c(6, 6),
          card(
            card_header("Downloads"),
            layout_columns(
              col_widths = c(6, 6),
              downloadButton("download_filtered", "Download Filtered Data"),
              downloadButton("download_plot", "Download Plot as PNG")
            )
          ),
          card(
            card_header("Summary Statistics"),
            tableOutput("summaryStats")
          )
        ),

        layout_columns(
          col_widths = c(6, 6),
          card(
            card_header("Table Preview (first 10 rows after filtering)"),
            tableOutput("preview")
          ),
          card(
            card_header("AI Insights"),
            verbatimTextOutput("aiInsights"),
            layout_columns(
              col_widths = c(4, 4, 4),
              actionButton("btn_corr", "Highlight Strongest Correlation"),
              actionButton("btn_var", "Highlight Highest Variance"),
              actionButton("btn_outlier", "Highlight Outlier Column")
            ),
            uiOutput("ai_highlight"),
            plotOutput("cor_heatmap", height = "400px"),
            downloadButton("download_report", "Download AI Report (PDF)")
          )
        )
      )
    ),

    # ---- TAB 2: DASHBOARD (New Interactive View) ----
    nav_panel(
      "Dashboard",
      layout_column_wrap(
        width = 1,
        uiOutput("dashboard_builder_ui"),
        uiOutput("dashboard_grid")
      )
    )
  )
)

server <- function(input, output, session) {
  user_message <- reactiveVal("Please enter your name, choose a number, and click Submit.")

  # ---- DASHBOARD STATE MANAGEMENT ----
  dashboard_state <- reactiveVal(list())
  all_dashboards <- reactiveVal(list())
  
  # Define missing operator helper
  `%||%` <- function(x, y) if (is.null(x)) y else x
  
  # Store for dashboard components (name, type, config)
  dashboard_components <- reactiveVal(list(
    list(id = 1, name = "Main Chart", type = "Chart", active = TRUE),
    list(id = 2, name = "Key Metrics", type = "KPI Card", active = TRUE),
    list(id = 3, name = "Data Table", type = "Table", active = TRUE)
  ))
  next_component_id <- reactiveVal(4)

  # ---- KPI CALCULATION FUNCTIONS ----
  calculate_kpis <- function(df) {
    if (is.null(df) || nrow(df) == 0) return(list())
    
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    if (length(numeric_cols) == 0) return(list())
    
    kpis <- list()
    
    for (col in numeric_cols) {
      col_data <- df[[col]]
      col_clean <- col_data[!is.na(col_data)]
      
      if (length(col_clean) > 0) {
        kpis[[col]] <- list(
          column = col,
          average = mean(col_clean, na.rm = TRUE),
          median = median(col_clean, na.rm = TRUE),
          min = min(col_clean, na.rm = TRUE),
          max = max(col_clean, na.rm = TRUE),
          count = length(col_clean),
          missing = sum(is.na(col_data))
        )
      }
    }
    
    kpis
  }

  format_kpi_value <- function(value) {
    if (is.numeric(value)) {
      if (abs(value) >= 1000000) {
        return(paste0(round(value / 1000000, 2), "M"))
      } else if (abs(value) >= 1000) {
        return(paste0(round(value / 1000, 1), "K"))
      } else {
        return(format(round(value, 2), nsmall = 2))
      }
    }
    return(as.character(value))
  }

  # ---- DASHBOARD COMPONENT MANAGEMENT ----
  observeEvent(input$add_dashboard_component, {
    req(input$dashboard_component_type, input$dashboard_component_name)
    
    current_components <- dashboard_components()
    new_id <- next_component_id()
    
    new_component <- list(
      id = new_id,
      name = input$dashboard_component_name,
      type = input$dashboard_component_type,
      active = TRUE,
      created_at = Sys.time()
    )
    
    current_components[[new_id]] <- new_component
    dashboard_components(current_components)
    next_component_id(new_id + 1)
    
    showNotification(
      sprintf("Component '%s' added to dashboard!", input$dashboard_component_name),
      type = "message",
      duration = 2
    )
    
    # Clear inputs
    updateTextInput(session, "dashboard_component_name", value = "")
  }, ignoreInit = TRUE)

  # ---- RENDER DASHBOARD GRID ----
  output$dashboard_grid <- renderUI({
    df <- filtered_data()
    req(df)
    
    components <- dashboard_components()
    if (length(components) == 0) {
      return(div(
        class = "alert alert-info",
        "No dashboard components added yet. Use the Dashboard Builder to add charts, KPIs, tables, or insights."
      ))
    }
    
    component_outputs <- lapply(seq_along(components), function(i) {
      comp <- components[[i]]
      if (!comp$active) return(NULL)
      
      card(
        full_screen = TRUE,
        card_header(
          tagList(
            comp$name,
            span(
              class = "float-end",
              actionButton(
                paste0("remove_component_", comp$id),
                "Remove",
                class = "btn-sm btn-danger"
              )
            )
          )
        ),
        if (comp$type == "Chart") {
          with_optional_spinner(plotOutput(paste0("dashboard_chart_", comp$id), height = "400px"))
        } else if (comp$type == "KPI Card") {
          uiOutput(paste0("dashboard_kpi_", comp$id))
        } else if (comp$type == "Table") {
          with_optional_spinner(tableOutput(paste0("dashboard_table_", comp$id)))
        } else if (comp$type == "AI Insight") {
          verbatimTextOutput(paste0("dashboard_insight_", comp$id))
        }
      )
    })
    
    # Render components in a flexible grid layout
    do.call(layout_column_wrap, c(list(width = 1), component_outputs))
  })

  # ---- RENDER INDIVIDUAL DASHBOARD CHARTS ----
  observe({
    df <- filtered_data()
    components <- dashboard_components()
    
    for (comp in components) {
      if (comp$active && comp$type == "Chart") {
        local({
          chart_id <- comp$id
          comp_name <- comp$name
          
          output[[paste0("dashboard_chart_", chart_id)]] <- renderPlot({
            req(df, input$xcol, input$ycol)
            
            pd <- plot_data()
            clusters <- cluster_info()$labels
            
            palette_cols <- c("#1f77b4", "#2ca02c", "#ff7f0e", "#9467bd", "#d62728")
            base_col <- rep("steelblue", nrow(df))
            cluster_idx <- !is.na(clusters)
            if (any(cluster_idx)) {
              base_col[cluster_idx] <- palette_cols[((clusters[cluster_idx] - 1) %% length(palette_cols)) + 1]
            }
            
            plot(pd$x, pd$y, 
                 xlab = input$xcol, ylab = input$ycol,
                 main = comp_name,
                 pch = 19, col = base_col, cex = 0.8)
            
            fit <- regression_model()
            if (!is.null(fit)) abline(fit, col = "darkgreen", lwd = 2)
          })
        })
      }
    }
  })

  # ---- RENDER INDIVIDUAL DASHBOARD KPI CARDS ----
  observe({
    df <- filtered_data()
    components <- dashboard_components()
    kpis <- calculate_kpis(df)
    
    for (comp in components) {
      if (comp$active && comp$type == "KPI Card") {
        local({
          kpi_id <- comp$id
          
          output[[paste0("dashboard_kpi_", kpi_id)]] <- renderUI({
            if (length(kpis) == 0) {
              return(div(
                class = "alert alert-warning",
                "No numeric columns available for KPI calculation."
              ))
            }
            
            # Create KPI cards for all numeric columns
            kpi_cards <- lapply(kpis, function(kpi) {
              div(
                class = "kpi-card",
                style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; margin: 10px 0; border-radius: 8px; text-align: center;",
                div(
                  style = "font-size: 14px; opacity: 0.9; margin-bottom: 10px;",
                  strong(kpi$column)
                ),
                div(
                  style = "font-size: 28px; font-weight: bold; margin-bottom: 5px;",
                  format_kpi_value(kpi$average)
                ),
                div(
                  style = "font-size: 12px; opacity: 0.8;",
                  paste("Avg | Range:", format_kpi_value(kpi$min), "-", format_kpi_value(kpi$max))
                ),
                div(
                  style = "font-size: 11px; opacity: 0.7; margin-top: 8px;",
                  paste("n =", kpi$count, "| Missing:", kpi$missing)
                )
              )
            })
            
            do.call(tagList, kpi_cards)
          })
        })
      }
    }
  })

  # ---- RENDER INDIVIDUAL DASHBOARD TABLES ----
  observe({
    df <- filtered_data()
    components <- dashboard_components()
    
    for (comp in components) {
      if (comp$active && comp$type == "Table") {
        local({
          table_id <- comp$id
          
          output[[paste0("dashboard_table_", table_id)]] <- renderTable({
            head(df, 20)
          }, striped = TRUE, bordered = TRUE)
        })
      }
    }
  })

  # ---- RENDER INDIVIDUAL DASHBOARD AI INSIGHTS ----
  observe({
    components <- dashboard_components()
    
    for (comp in components) {
      if (comp$active && comp$type == "AI Insight") {
        local({
          insight_id <- comp$id
          
          output[[paste0("dashboard_insight_", insight_id)]] <- renderText({
            ai_text <- ai_insights_text()
            if (is.null(ai_text)) {
              return("AI insights will appear here once data is loaded.")
            }
            ai_text
          })
        })
      }
    }
  })

  # ---- REMOVE COMPONENT HANDLERS ----
  observe({
    components <- dashboard_components()
    
    for (comp in components) {
      observeEvent(input[[paste0("remove_component_", comp$id)]], {
        current <- dashboard_components()
        current[[paste0(comp$id)]] <- NULL
        # Rebuild list without NULL entries
        current <- Filter(function(x) !is.null(x), current)
        dashboard_components(current)
        showNotification("Component removed from dashboard", type = "message", duration = 2)
      }, ignoreInit = TRUE, once = FALSE)
    }
  })

  # ---- SAVE DASHBOARD STATE ----
  observeEvent(input$save_dashboard_btn, {
    req(input$dashboard_name)
    
    dashboard_data <- list(
      name = input$dashboard_name,
      created_at = Sys.time(),
      components = dashboard_components(),
      filters = list(
        xcol = input$xcol,
        ycol = input$ycol,
        x_numeric_filter = input$x_numeric_filter %||% NULL,
        x_categorical_filter = input$x_categorical_filter %||% NULL
      )
    )
    
    current_dashboards <- all_dashboards()
    current_dashboards[[input$dashboard_name]] <- dashboard_data
    all_dashboards(current_dashboards)
    
    # Update dropdown
    updateSelectInput(session, "saved_dashboards", 
                     choices = names(current_dashboards),
                     selected = input$dashboard_name)
    
    showNotification(
      sprintf("Dashboard '%s' saved successfully!", input$dashboard_name),
      type = "message",
      duration = 3
    )
  }, ignoreInit = TRUE)

  # ---- LOAD DASHBOARD STATE ----
  observeEvent(input$load_dashboard_btn, {
    req(input$saved_dashboards)
    
    all_dbs <- all_dashboards()
    dashboard_data <- all_dbs[[input$saved_dashboards]]
    
    if (!is.null(dashboard_data)) {
      # Restore components
      dashboard_components(dashboard_data$components)
      
      # Restore filters
      if (!is.null(dashboard_data$filters$xcol)) {
        updateSelectInput(session, "xcol", selected = dashboard_data$filters$xcol)
      }
      if (!is.null(dashboard_data$filters$ycol)) {
        updateSelectInput(session, "ycol", selected = dashboard_data$filters$ycol)
      }
      
      showNotification(
        sprintf("Dashboard '%s' loaded!", input$saved_dashboards),
        type = "message",
        duration = 3
      )
    }
  }, ignoreInit = TRUE)

  # ---- DELETE DASHBOARD ----
  observeEvent(input$delete_dashboard_btn, {
    req(input$saved_dashboards)
    
    current_dashboards <- all_dashboards()
    current_dashboards[[input$saved_dashboards]] <- NULL
    current_dashboards <- Filter(function(x) !is.null(x), current_dashboards)
    all_dashboards(current_dashboards)
    
    updateSelectInput(session, "saved_dashboards", 
                     choices = names(current_dashboards),
                     selected = if (length(current_dashboards) > 0) names(current_dashboards)[1] else "")
    
    showNotification("Dashboard deleted", type = "message", duration = 2)
  }, ignoreInit = TRUE)

  # ---- UPDATE SAVED DASHBOARDS DROPDOWN ----
  observe({
    all_dbs <- all_dashboards()
    updateSelectInput(session, "saved_dashboards", 
                     choices = names(all_dbs),
                     selected = NULL)
  })

  # ---- RENDER DASHBOARD BUILDER INFO ----
  output$dashboard_builder_ui <- renderUI({
    components <- dashboard_components()
    active_count <- sum(sapply(components, function(x) x$active))
    
    card(
      card_header("Dashboard Information"),
      div(
        p(strong("Active Components:"), active_count),
        p(strong("Total Components:"), length(components)),
        p(strong("Saved Dashboards:"), length(all_dashboards())),
        br(),
        p(
          "Use the sidebar controls to add/remove components, save/load dashboards, ",
          "and apply filters. All dashboard components update automatically with filters."
        )
      )
    )
  })

  # ---- DATASET PROFILING FUNCTIONS ----
  profile_dataset <- function(df) {
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    profile <- list(
      rows = nrow(df),
      cols = ncol(df),
      col_names = names(df),
      col_types = vapply(df, class, character(1)),
      missing_counts = colSums(is.na(df)),
      numeric_cols = names(df)[sapply(df, is.numeric)]
    )
    
    # Calculate numeric summaries only for numeric columns
    if (length(profile$numeric_cols) > 0) {
      numeric_df <- df[, profile$numeric_cols, drop = FALSE]
      profile$numeric_summary <- list(
        means = colMeans(numeric_df, na.rm = TRUE),
        medians = sapply(numeric_df, median, na.rm = TRUE),
        sds = sapply(numeric_df, sd, na.rm = TRUE),
        mins = sapply(numeric_df, min, na.rm = TRUE),
        maxs = sapply(numeric_df, max, na.rm = TRUE)
      )
    }
    
    profile
  }

  # ---- FORECASTING FUNCTIONS ----
  forecast_linear <- function(x, periods = 10) {
    # Simple linear regression forecasting
    if (is.null(x) || length(x) < 3) return(NULL)
    
    # Remove NAs
    x_clean <- x[!is.na(x)]
    if (length(x_clean) < 3) return(NULL)
    
    # Create time index
    n <- length(x_clean)
    t <- seq_len(n)
    t_future <- seq(n + 1, n + periods)
    
    # Fit linear model
    fit <- lm(y ~ x, data = data.frame(y = x_clean, x = t))
    
    # Predict future values
    future_df <- data.frame(x = t_future)
    predictions <- predict(fit, newdata = future_df)
    
    # Calculate confidence intervals
    pred_se <- predict(fit, newdata = future_df, se.fit = TRUE)
    ci_lower <- pred_se$fit - 1.96 * pred_se$se.fit
    ci_upper <- pred_se$fit + 1.96 * pred_se$se.fit
    
    list(
      observed = x_clean,
      predicted = as.numeric(predictions),
      ci_lower = as.numeric(ci_lower),
      ci_upper = as.numeric(ci_upper),
      periods = periods,
      model = fit,
      trend_direction = if (coef(fit)[2] > 0) "upward" else "downward",
      trend_value = coef(fit)[2]
    )
  }

  # ---- UPDATE FORECAST TARGET CHOICES ----
  observe({
    df <- data_raw()
    req(df)
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    if (length(numeric_cols) > 0) {
      updateSelectInput(session, "forecast_target", choices = numeric_cols, selected = numeric_cols[1])
    }
  })

  observeEvent(input$go, {
    safe_name <- trimws(input$name)
    if (is.null(safe_name) || safe_name == "") {
      user_message("Please enter a valid name before submitting.")
      return()
    }
    if (is.null(input$num) || !is.numeric(input$num) || is.na(input$num)) {
      user_message("Please select a valid number before submitting.")
      return()
    }
    user_message(sprintf("Hello %s, you selected %s", safe_name, input$num))
  }, ignoreInit = TRUE)

  # ---- Forecast trigger ----
  forecast_trigger <- reactiveVal(0)
  observeEvent(input$run_forecast, {
    forecast_trigger(forecast_trigger() + 1)
    showNotification("Forecast generated successfully!", type = "message", duration = 2)
  }, ignoreInit = TRUE)

  # ---- data_raw(): read uploaded CSV once per upload ----
  data_raw <- reactive({
    req(input$file1)

    if (!grepl("\\.csv$", tolower(input$file1$name))) {
      validate(need(FALSE, "Invalid file type: please upload a .csv file."))
    }

    if (is.null(input$file1$size) || input$file1$size >= 5 * 1024 * 1024) {
      showNotification("File is too large. Please upload a CSV smaller than 5 MB.", type = "warning", duration = 4)
      validate(need(FALSE, "File is too large. Please upload a CSV smaller than 5 MB."))
    }

    withProgress(message = "Loading CSV file...", value = 0, {
      incProgress(0.25)
      df <- tryCatch(
        read.csv(input$file1$datapath, stringsAsFactors = FALSE),
        error = function(e) validate(need(FALSE, paste("Unable to read CSV:", conditionMessage(e))))
      )
      incProgress(0.75)
      df
    })
  })

  observeEvent(input$file1, {
    req(input$file1)
    showNotification(sprintf("Upload successful: %s", input$file1$name), type = "message", duration = 3)
  }, ignoreInit = TRUE)

  observe({
    df <- data_raw()
    req(df)
    cols <- names(df)
    validate(need(length(cols) > 0, "Uploaded CSV has no columns."))

    current_x <- isolate(input$xcol)
    current_y <- isolate(input$ycol)
    selected_x <- if (!is.null(current_x) && current_x %in% cols) current_x else cols[1]
    selected_y <- if (!is.null(current_y) && current_y %in% cols) current_y else cols[min(2, length(cols))]

    updateSelectInput(session, "xcol", choices = cols, selected = selected_x)
    updateSelectInput(session, "ycol", choices = cols, selected = selected_y)
  })

  output$x_filter_ui <- renderUI({
    df <- data_raw()
    req(input$xcol)
    validate(need(input$xcol %in% names(df), "Selected X column does not exist."))

    x <- df[[input$xcol]]
    if (is.numeric(x)) {
      rng <- range(x, na.rm = TRUE)
      if (!all(is.finite(rng))) return(helpText("X column has no finite numeric values to filter."))

      sliderInput(
        "x_numeric_filter", "Filter X range",
        min = rng[1], max = rng[2], value = rng,
        step = max((rng[2] - rng[1]) / 100, .Machine$double.eps)
      )
    } else {
      values <- sort(unique(as.character(x)))
      values <- values[!is.na(values)]
      if (length(values) == 0) return(helpText("X column has no values available for filtering."))

      checkboxGroupInput("x_categorical_filter", "Filter X values", choices = values, selected = values)
    }
  })

  observeEvent(list(input$x_numeric_filter, input$x_categorical_filter), {
    req(input$xcol)
    showNotification("Filters updated.", type = "message", duration = 1.5)
  }, ignoreInit = TRUE)

  # ---- filtered_data(): apply current filter to raw data ----
  filtered_data <- reactive({
    df <- data_raw()
    req(input$xcol, input$ycol)

    validate(
      need(input$xcol %in% names(df), "Selected X column does not exist in uploaded data."),
      need(input$ycol %in% names(df), "Selected Y column does not exist in uploaded data.")
    )

    x <- df[[input$xcol]]
    if (is.numeric(x)) {
      req(input$x_numeric_filter)
      bounds <- input$x_numeric_filter
      df <- df[!is.na(x) & x >= bounds[1] & x <= bounds[2], , drop = FALSE]
    } else {
      req(input$x_categorical_filter)
      df <- df[as.character(x) %in% input$x_categorical_filter, , drop = FALSE]
    }

    validate(need(nrow(df) > 0, "No rows remain after filtering. Adjust filter settings."))
    df
  })

  data_filtered <- filtered_data

  plot_data <- reactive({
    df <- filtered_data()
    validate(
      need(input$xcol %in% names(df), "Selected X column does not exist."),
      need(input$ycol %in% names(df), "Selected Y column does not exist.")
    )

    x <- df[[input$xcol]]
    y <- df[[input$ycol]]
    validate(
      need(is.numeric(x) || is.factor(x) || is.character(x), "X column must be numeric/categorical for plotting."),
      need(is.numeric(y) || is.factor(y) || is.character(y), "Y column must be numeric/categorical for plotting.")
    )
    list(x = x, y = y)
  })

  # ---- regression_model(): linear model + trend text support ----
  regression_model <- reactive({
    df <- filtered_data()
    x <- df[[input$xcol]]
    y <- df[[input$ycol]]
    if (!(is.numeric(x) && is.numeric(y))) return(NULL)

    fit_df <- data.frame(x = x, y = y)
    fit_df <- fit_df[stats::complete.cases(fit_df), , drop = FALSE]
    if (nrow(fit_df) < 2) return(NULL)

    stats::lm(y ~ x, data = fit_df)
  })

  # ---- cluster_info(): k-means clusters + summaries for insights ----
  cluster_info <- reactive({
    df <- filtered_data()
    numeric_df <- df[vapply(df, is.numeric, logical(1))]

    labels <- rep(NA_integer_, nrow(df))
    summary_text <- "Cluster summary unavailable (need >=2 numeric columns with enough complete rows)."

    if (ncol(numeric_df) < 2) {
      return(list(labels = labels, summary_text = summary_text))
    }

    cc <- stats::complete.cases(numeric_df)
    idx <- which(cc)
    if (length(idx) < 3) {
      return(list(labels = labels, summary_text = summary_text))
    }

    k <- min(3, length(idx))
    km <- stats::kmeans(numeric_df[idx, , drop = FALSE], centers = k)
    labels[idx] <- km$cluster

    cluster_sizes <- table(km$cluster)
    size_txt <- paste0("Cluster sizes: ", paste(paste0("C", names(cluster_sizes), "=", as.integer(cluster_sizes)), collapse = ", "))

    mean_by_cluster <- stats::aggregate(numeric_df[idx, , drop = FALSE], by = list(cluster = km$cluster), FUN = mean)
    median_by_cluster <- stats::aggregate(numeric_df[idx, , drop = FALSE], by = list(cluster = km$cluster), FUN = median)

    mean_txt <- apply(mean_by_cluster, 1, function(r) {
      paste0("C", r["cluster"], " mean {", paste(paste(names(r)[-1], round(as.numeric(r[-1]), 2), sep = "="), collapse = ", "), "}")
    })
    median_txt <- apply(median_by_cluster, 1, function(r) {
      paste0("C", r["cluster"], " median {", paste(paste(names(r)[-1], round(as.numeric(r[-1]), 2), sep = "="), collapse = ", "), "}")
    })

    summary_text <- paste(size_txt, paste(mean_txt, collapse = "; "), paste(median_txt, collapse = "; "), sep = "\n")

    list(labels = labels, summary_text = summary_text)
  })

  # ---- anomaly_zscore(): z-score anomalies (|z| > 2) for ML insight + overlay ----
  anomaly_zscore <- reactive({
    df <- filtered_data()
    numeric_df <- df[vapply(df, is.numeric, logical(1))]

    row_flags <- rep(FALSE, nrow(df))
    counts <- numeric(0)

    if (ncol(numeric_df) == 0 || nrow(numeric_df) == 0) {
      return(list(row_flags = row_flags, counts = counts))
    }

    counts <- vapply(names(numeric_df), function(col_name) {
      x <- numeric_df[[col_name]]
      z <- as.numeric(scale(x))
      z[is.na(z)] <- 0
      col_flags <- abs(z) > 2
      row_flags <<- row_flags | col_flags
      sum(col_flags, na.rm = TRUE)
    }, numeric(1))

    list(row_flags = row_flags, counts = counts)
  })

  # ---- ai_insights_raw(): backend statistical insight engine ----
  ai_insights_raw <- reactive({
    df <- filtered_data()
    req(df)

    numeric_df <- df[vapply(df, is.numeric, logical(1))]
    if (ncol(numeric_df) < 2) return(NULL)

    cor_mat <- stats::cor(numeric_df, use = "complete.obs")
    diag(cor_mat) <- NA_real_

    if (all(is.na(cor_mat))) {
      strongest_pair <- c(NA_character_, NA_character_)
      correlation_value <- NA_real_
    } else {
      max_idx <- which(abs(cor_mat) == max(abs(cor_mat), na.rm = TRUE), arr.ind = TRUE)[1, ]
      strongest_pair <- c(colnames(cor_mat)[max_idx[1]], colnames(cor_mat)[max_idx[2]])
      correlation_value <- unname(cor_mat[max_idx[1], max_idx[2]])
    }

    variances <- vapply(numeric_df, stats::var, numeric(1), na.rm = TRUE)
    highest_variance_column <- if (length(variances) == 0 || all(is.na(variances))) NA_character_ else names(variances)[which.max(variances)]

    outlier_counts <- vapply(names(numeric_df), function(col_name) {
      x <- numeric_df[[col_name]]
      q1 <- stats::quantile(x, 0.25, na.rm = TRUE, names = FALSE)
      q3 <- stats::quantile(x, 0.75, na.rm = TRUE, names = FALSE)
      iqr_value <- q3 - q1
      lower <- q1 - 1.5 * iqr_value
      upper <- q3 + 1.5 * iqr_value
      sum(x < lower | x > upper, na.rm = TRUE)
    }, numeric(1))

    list(
      strongest_pair = strongest_pair,
      correlation_value = correlation_value,
      highest_variance_column = highest_variance_column,
      outlier_counts = outlier_counts
    )
  })

  # ---- ai_insights_text(): narrative + ML summaries (trend, clusters, anomalies, forecasts) ----
  ai_insights_text <- reactive({
    insights <- ai_insights_raw()
    if (is.null(insights)) return(NULL)

    correlation_insight <- strongest_correlation_insight()
    outlier_counts <- insights$outlier_counts
    var_result <- variance_insight()

    relationship_text <- if (!is.null(correlation_insight)) {
      paste("Strongest Relationship Insight:", correlation_insight$interpretation)
    } else {
      "Strongest Relationship Insight: No reliable strongest relationship could be determined."
    }

    variability_text <- if (!is.null(var_result)) {
      paste("Variability Insight:", var_result$interpretation)
    } else {
      "Variability Insight: No numeric columns were available to assess variability."
    }

    iqr_outlier_text <- if (is.null(outlier_counts) || length(outlier_counts) == 0 || all(outlier_counts < 1)) {
      "No significant IQR outliers were detected."
    } else {
      flagged <- outlier_counts[outlier_counts >= 1]
      paste("IQR outliers were detected in:", paste(paste0(names(flagged), " (", as.integer(flagged), ")"), collapse = ", "), ".")
    }

    health <- dataset_health()
    health_text <- paste0(
      "Dataset Health Score: ", health$total_score, " / 100 (", health$level, ")",
      "\nCorrelation Score: ", health$corr_score, " / 25",
      "\nOutlier Stability: ", health$outlier_score, " / 25",
      "\nVariance Balance: ", health$variance_score, " / 25",
      "\nMissing Data Quality: ", health$missing_score, " / 25",
      "\nOverall Assessment: ", health$comment
    )

    # Predicted trend text from linear model.
    fit <- regression_model()
    trend_text <- if (is.null(fit)) {
      "Predicted trend unavailable (X and Y must both be numeric with enough complete rows)."
    } else {
      coef_fit <- stats::coef(fit)
      paste0("Predicted trend: ", input$ycol, " = ", round(coef_fit[[2]], 4), "*", input$xcol, " + ", round(coef_fit[[1]], 4), ".")
    }

    # Cluster summary text.
    cluster_txt <- cluster_info()$summary_text

    # Z-score anomaly summary text.
    z_counts <- anomaly_zscore()$counts
    z_text <- if (length(z_counts) == 0 || all(z_counts == 0)) {
      "Z-score anomalies (|z| > 2): none detected."
    } else {
      flagged <- z_counts[z_counts > 0]
      paste("Z-score anomalies (|z| > 2):", paste(paste0(names(flagged), " (", as.integer(flagged), ")"), collapse = ", "), ".")
    }

    # FORECASTING INSIGHT (NEW)
    forecast_text <- if (is.null(input$forecast_target) || isolate(forecast_trigger()) == 0) {
      "Forecast: Not yet generated. Provide target variable and click 'Generate Forecast' to enable time-series predictions."
    } else {
      forecast <- forecast_results()
      if (is.null(forecast)) {
        "Forecast: Could not generate forecast for selected target. Required at least 3 valid observations."
      } else {
        avg_pred <- mean(forecast$predicted, na.rm = TRUE)
        min_pred <- min(forecast$predicted, na.rm = TRUE)
        max_pred <- max(forecast$predicted, na.rm = TRUE)
        trend_direction <- forecast$trend_direction
        trend_rate <- round(forecast$trend_value, 4)
        
        paste0(
          "Forecast Insight: ", input$forecast_target, " is trending ", trend_direction, 
          " (rate: ", trend_rate, " per period). ",
          "Predicted average value in next period: ", round(avg_pred, 2), ". ",
          "Expected range: ", round(min_pred, 2), " to ", round(max_pred, 2), "."
        )
      }
    }

    paste(
      relationship_text,
      variability_text,
      iqr_outlier_text,
      health_text,
      trend_text,
      cluster_txt,
      z_text,
      forecast_text,
      sep = "\n\n"
    )
  })

  selected_highlight <- reactiveVal(NULL)
  observeEvent(input$btn_corr, {
    selected_highlight("correlation")
  }, ignoreInit = TRUE)
  observeEvent(input$btn_var, {
    selected_highlight("variance")
  }, ignoreInit = TRUE)
  observeEvent(input$btn_outlier, {
    selected_highlight("outlier")
  }, ignoreInit = TRUE)

  cor_matrix <- reactive({
    df <- filtered_data()
    if (nrow(df) <= 2) return(NULL)

    numeric_df <- df[sapply(df, is.numeric)]
    if (ncol(numeric_df) <= 1) return(NULL)

    stats::cor(numeric_df, use = "complete.obs")
  })

  interpret_correlation <- function(col1, col2, r, dataset_size) {
    abs_r <- abs(r)

    if (abs_r < 0.3) {
      strength <- "weak"
    } else if (abs_r < 0.6) {
      strength <- "moderate"
    } else {
      strength <- "strong"
    }

    direction <- if (r > 0) "positive" else "negative"

    interpretation <- paste0(
      col1, " and ", col2, " show a ", strength, " ", direction,
      " relationship (r = ", format(round(r, 3), nsmall = 3), "). "
    )

    if (direction == "positive") {
      interpretation <- paste0(interpretation, "As ", col1, " increases, ", col2, " tends to increase as well. ")
    } else {
      interpretation <- paste0(interpretation, "As ", col1, " increases, ", col2, " tends to decrease. ")
    }

    if (isTRUE(all.equal(abs_r, 1.0))) {
      interpretation <- paste0(interpretation, "This represents a near-perfect linear relationship. ")
    }

    if (dataset_size < 10) {
      interpretation <- paste0(interpretation, "Note: Small dataset size may affect reliability of this insight.")
    }

    list(
      strength = strength,
      direction = direction,
      interpretation = interpretation
    )
  }

  strongest_correlation_insight <- reactive({
    cm <- cor_matrix()
    if (is.null(cm) || !is.matrix(cm) || ncol(cm) < 2) return(NULL)

    temp_cm <- cm
    diag(temp_cm) <- NA_real_

    if (all(is.na(temp_cm))) return(NULL)

    max_idx <- which(abs(temp_cm) == max(abs(temp_cm), na.rm = TRUE), arr.ind = TRUE)[1, ]
    var1 <- colnames(temp_cm)[max_idx[1]]
    var2 <- colnames(temp_cm)[max_idx[2]]
    corr_value <- unname(temp_cm[max_idx[1], max_idx[2]])

    if (is.na(corr_value)) return(NULL)

    interp <- interpret_correlation(var1, var2, corr_value, nrow(filtered_data()))

    list(
      var1 = var1,
      var2 = var2,
      r = corr_value,
      strength = interp$strength,
      direction = interp$direction,
      interpretation = interp$interpretation
    )
  })

  highest_variance <- reactive({
    df <- filtered_data()
    numeric_df <- df[sapply(df, is.numeric)]
    if (ncol(numeric_df) == 0) return(NULL)

    vars <- apply(numeric_df, 2, var)
    if (length(vars) == 0 || all(is.na(vars))) return(NULL)

    names(which.max(vars))
  })

  interpret_variance <- function(column_name, variance_value, all_variances) {
    if (is.null(column_name) || is.na(column_name) || !nzchar(column_name)) return(NULL)
    if (is.null(all_variances) || length(all_variances) == 0) return(NULL)

    valid_variances <- all_variances[!is.na(all_variances)]
    if (length(valid_variances) == 0) return(NULL)

    if (isTRUE(all.equal(variance_value, 0))) {
      interpretation <- paste0(
        column_name, " shows no variability. ",
        "All values in this column are identical."
      )
      return(list(level = "no variability", interpretation = interpretation))
    }

    avg_variance <- sum(valid_variances) / length(valid_variances)

    if (avg_variance == 0) {
      level <- "high"
    } else if (variance_value < 0.75 * avg_variance) {
      level <- "low"
    } else if (variance_value <= 1.25 * avg_variance) {
      level <- "moderate"
    } else {
      level <- "high"
    }

    interpretation <- paste0(
      column_name, " exhibits ", level, " variability within the dataset. "
    )

    if (level == "high") {
      interpretation <- paste0(
        interpretation,
        "This indicates a wide distribution of values, suggesting significant dispersion and potential diversity across observations."
      )
    } else if (level == "moderate") {
      interpretation <- paste0(
        interpretation,
        "Values are moderately spread out, indicating balanced distribution."
      )
    } else {
      interpretation <- paste0(
        interpretation,
        "Values are tightly clustered, suggesting consistency across records."
      )
    }

    list(level = level, interpretation = interpretation)
  }

  variance_insight <- reactive({
    df <- filtered_data()
    numeric_df <- df[sapply(df, is.numeric)]
    if (ncol(numeric_df) == 0) return(NULL)

    vars <- apply(numeric_df, 2, var)
    if (length(vars) == 0 || all(is.na(vars))) return(NULL)

    highest_var_col <- highest_variance()
    if (is.null(highest_var_col) || !(highest_var_col %in% names(vars))) return(NULL)

    highest_var_value <- unname(vars[[highest_var_col]])
    if (is.na(highest_var_value)) return(NULL)

    interpret_variance(
      highest_var_col,
      highest_var_value,
      vars
    )
  })

  outlier_column <- reactive({
    df <- filtered_data()
    numeric_df <- df[sapply(df, is.numeric)]
    if (ncol(numeric_df) == 0) return(NULL)

    z_scores <- scale(numeric_df)
    anomaly_counts <- colSums(abs(z_scores) > 2, na.rm = TRUE)

    if (all(anomaly_counts == 0)) {
      return(NULL)
    } else {
      return(names(which.max(anomaly_counts)))
    }
  })

  interpret_outliers <- function(column_name, outlier_count, dataset_size) {
    if (dataset_size == 0) return(NULL)

    ratio <- outlier_count / dataset_size

    if (ratio < 0.05) {
      severity <- "low"
    } else if (ratio <= 0.15) {
      severity <- "moderate"
    } else {
      severity <- "high"
    }

    interpretation <- paste0(
      column_name, " contains a ", severity,
      " concentration of statistical outliers (",
      outlier_count, " detected, ", sprintf("%.1f%%", ratio * 100),
      " of dataset). "
    )

    if (severity == "high") {
      interpretation <- paste0(
        interpretation,
        "This suggests significant dispersion or potential data quality concerns. ",
        "Extreme values may represent rare events or measurement inconsistencies."
      )
    } else if (severity == "moderate") {
      interpretation <- paste0(
        interpretation,
        "Some extreme values are present, which may indicate natural variability ",
        "or emerging subgroups within the dataset."
      )
    } else {
      interpretation <- paste0(
        interpretation,
        "Outliers are minimal, suggesting a relatively stable and consistent distribution."
      )
    }

    if (dataset_size < 10) {
      interpretation <- paste0(
        interpretation,
        " Note: Small dataset size may reduce anomaly detection reliability."
      )
    }

    list(
      severity = severity,
      ratio = ratio,
      interpretation = interpretation
    )
  }

  outlier_insight <- reactive({
    df <- filtered_data()
    dataset_size <- nrow(df)
    if (dataset_size == 0) return(NULL)

    numeric_df <- df[sapply(df, is.numeric)]
    if (ncol(numeric_df) == 0) return(NULL)

    z_scores <- scale(numeric_df)
    anomaly_counts <- colSums(abs(z_scores) > 2, na.rm = TRUE)
    if (length(anomaly_counts) == 0 || all(is.na(anomaly_counts))) return(NULL)

    max_outliers <- max(anomaly_counts, na.rm = TRUE)
    if (!is.finite(max_outliers) || max_outliers == 0) {
      interpretation <- "No statistical outliers were detected across numeric columns. The dataset appears statistically stable."
      if (dataset_size < 10) {
        interpretation <- paste0(
          interpretation,
          " Note: Small dataset size may reduce anomaly detection reliability."
        )
      }
      return(list(
        severity = "none",
        ratio = 0,
        interpretation = interpretation
      ))
    }

    worst_col <- names(anomaly_counts)[which.max(anomaly_counts)]
    worst_count <- unname(anomaly_counts[[worst_col]])

    interpret_outliers(
      worst_col,
      worst_count,
      dataset_size
    )
  })


  calculate_dataset_health <- function(strongest_corr_value, max_outlier_ratio, variances, df) {
    abs_corr <- abs(strongest_corr_value)

    if (abs_corr > 0.6) {
      corr_score <- 25
    } else if (abs_corr > 0.4) {
      corr_score <- 18
    } else if (abs_corr > 0) {
      corr_score <- 10
    } else {
      corr_score <- 5
    }

    if (max_outlier_ratio < 0.05) {
      outlier_score <- 25
    } else if (max_outlier_ratio <= 0.15) {
      outlier_score <- 18
    } else {
      outlier_score <- 8
    }

    valid_variances <- variances[!is.na(variances)]
    if (length(valid_variances) > 1) {
      max_var <- max(valid_variances)
      avg_var <- sum(valid_variances) / length(valid_variances)

      if (max_var <= 1.5 * avg_var) {
        variance_score <- 25
      } else if (max_var <= 2.5 * avg_var) {
        variance_score <- 18
      } else {
        variance_score <- 10
      }
    } else if (length(valid_variances) == 1) {
      variance_score <- 15
    } else {
      variance_score <- 10
    }

    total_cells <- nrow(df) * ncol(df)
    missing_cells <- sum(is.na(df))
    missing_ratio <- if (total_cells > 0) missing_cells / total_cells else 0

    if (missing_ratio <= 0.02) {
      missing_score <- 25
    } else if (missing_ratio <= 0.10) {
      missing_score <- 18
    } else {
      missing_score <- 8
    }

    total_score <- corr_score + outlier_score + variance_score + missing_score

    list(
      total_score = total_score,
      corr_score = corr_score,
      outlier_score = outlier_score,
      variance_score = variance_score,
      missing_score = missing_score,
      missing_ratio = missing_ratio
    )
  }

  interpret_health_score <- function(score) {
    if (score >= 85) {
      level <- "Excellent"
      comment <- "The dataset is highly stable with strong structural integrity."
    } else if (score >= 70) {
      level <- "Good"
      comment <- "The dataset is statistically sound with minor irregularities."
    } else if (score >= 50) {
      level <- "Moderate"
      comment <- "The dataset shows structural inconsistencies that may require cleaning."
    } else {
      level <- "Poor"
      comment <- "The dataset has significant statistical weaknesses and requires preprocessing."
    }

    list(level = level, comment = comment)
  }

  dataset_health <- reactive({
    df <- filtered_data()

    corr_info <- strongest_correlation_insight()
    outlier_info <- outlier_insight()

    numeric_df <- df[sapply(df, is.numeric)]
    variances <- if (ncol(numeric_df) > 0) apply(numeric_df, 2, var) else numeric(0)

    strongest_corr_value <- if (!is.null(corr_info) && !is.null(corr_info$r) && !is.na(corr_info$r)) corr_info$r else 0
    max_outlier_ratio <- if (!is.null(outlier_info) && !is.null(outlier_info$ratio) && !is.na(outlier_info$ratio)) outlier_info$ratio else 0

    health <- calculate_dataset_health(
      strongest_corr_value,
      max_outlier_ratio,
      variances,
      df
    )

    interpreted <- interpret_health_score(health$total_score)

    c(health, interpreted)
  })

  summary_stats <- reactive({
    df <- filtered_data()
    y <- df[[input$ycol]]
    validate(need(is.numeric(y), "Summary statistics are shown only when Y is numeric."))

    data.frame(
      Metric = c("Mean", "Median", "Standard Deviation", "Min", "Max"),
      Value = c(mean(y, na.rm = TRUE), median(y, na.rm = TRUE), sd(y, na.rm = TRUE), min(y, na.rm = TRUE), max(y, na.rm = TRUE)),
      check.names = FALSE
    )
  })

  # ---- REACTIVE: Dataset Profile ----
  dataset_profile_obj <- reactive({
    df <- filtered_data()
    req(df)
    profile_dataset(df)
  })

  # ---- REACTIVE: Forecast Results ----
  forecast_results <- eventReactive(forecast_trigger(), {
    df <- filtered_data()
    req(input$forecast_target, df)
    validate(need(input$forecast_target %in% names(df), "Selected forecast target does not exist."))
    
    target_data <- df[[input$forecast_target]]
    forecast_linear(target_data, periods = input$forecast_periods)
  })

  # ---- OUTPUT: Dataset Profile Table ----
  output$datasetProfile <- renderTable({
    profile <- dataset_profile_obj()
    req(profile)
    
    data.frame(
      Metric = c("Rows", "Columns", "Numeric Columns"),
      Value = c(profile$rows, profile$cols, length(profile$numeric_cols))
    )
  }, striped = TRUE, bordered = TRUE)

  # ---- OUTPUT: Dataset Profile Text (Missing Values + Column Types) ----
  output$datasetProfileText <- renderUI({
    profile <- dataset_profile_obj()
    req(profile)
    
    # Missing values summary
    missing_summary <- profile$missing_counts
    missing_text <- if (sum(missing_summary) == 0) {
      "<strong>Missing Values:</strong> None detected"
    } else {
      cols_with_missing <- names(missing_summary[missing_summary > 0])
      missing_str <- paste(paste0(cols_with_missing, ": ", missing_summary[cols_with_missing]), collapse = "<br/>")
      paste0("<strong>Missing Values:</strong><br/>", missing_str)
    }
    
    # Column types summary
    types_table <- data.frame(table(profile$col_types))
    types_text <- paste0(
      "<strong>Column Types:</strong><br/>",
      paste(paste0(types_table$Var1, ": ", types_table$Freq), collapse = "<br/>")
    )
    
    # Numeric summary if available
    numeric_text <- ""
    if (!is.null(profile$numeric_summary)) {
      numeric_text <- "<strong><br/>Numeric Summary (Mean ± SD):</strong><br/>"
      for (col in profile$numeric_cols) {
        mean_val <- round(profile$numeric_summary$means[col], 3)
        sd_val <- round(profile$numeric_summary$sds[col], 3)
        min_val <- round(profile$numeric_summary$mins[col], 3)
        max_val <- round(profile$numeric_summary$maxs[col], 3)
        numeric_text <- paste0(numeric_text, 
                               col, ": µ=", mean_val, " ± ", sd_val, 
                               " [", min_val, " to ", max_val, "]<br/>")
      }
    }
    
    HTML(paste0(missing_text, "<br/><br/>", types_text, numeric_text))
  })

  # ---- OUTPUT: Forecast Plot ----
  output$forecastPlot <- renderPlot({
    forecast <- forecast_results()
    req(forecast)
    
    n_obs <- length(forecast$observed)
    n_pred <- length(forecast$predicted)
    
    # Create x-axis values
    x_obs <- seq_len(n_obs)
    x_pred <- seq(n_obs + 1, n_obs + n_pred)
    
    # Plot observed data
    plot(x_obs, forecast$observed, 
         type = "l", col = "steelblue", lwd = 2,
         xlim = c(1, n_obs + n_pred),
         ylim = c(min(forecast$ci_lower, forecast$observed, na.rm = TRUE),
                  max(forecast$ci_upper, forecast$observed, na.rm = TRUE)),
         xlab = "Time Period", ylab = input$forecast_target,
         main = paste("Forecast of", input$forecast_target))
    
    # Add observed points
    points(x_obs, forecast$observed, col = "steelblue", pch = 19, cex = 0.8)
    
    # Add predicted line
    lines(x_pred, forecast$predicted, col = "darkred", lwd = 2, lty = 2)
    points(x_pred, forecast$predicted, col = "darkred", pch = 19, cex = 0.8)
    
    # Add confidence interval
    polygon(c(x_pred, rev(x_pred)), 
            c(forecast$ci_upper, rev(forecast$ci_lower)),
            col = rgb(1, 0, 0, 0.15), border = NA)
    
    # Add legend
    legend("topleft", 
           legend = c("Observed", "Predicted", "95% CI"),
           col = c("steelblue", "darkred", rgb(1, 0, 0, 0.3)),
           lwd = c(2, 2, 10),
           lty = c(1, 2, 1))
    
    # Add reference line at transition point
    abline(v = n_obs + 0.5, col = "gray", lty = 3, lwd = 1)
  })

  # ---- OUTPUT: Forecast Table ----
  output$forecastTable <- renderTable({
    forecast <- forecast_results()
    req(forecast)
    
    data.frame(
      Period = seq_len(length(forecast$predicted)),
      Predicted = round(forecast$predicted, 3),
      Lower_CI = round(forecast$ci_lower, 3),
      Upper_CI = round(forecast$ci_upper, 3)
    )
  }, striped = TRUE, bordered = TRUE)

  # ---- OUTPUT: Forecast Summary Text ----
  output$forecastSummary <- renderUI({
    forecast <- forecast_results()
    req(forecast)
    
    avg_pred <- mean(forecast$predicted, na.rm = TRUE)
    min_pred <- min(forecast$predicted, na.rm = TRUE)
    max_pred <- max(forecast$predicted, na.rm = TRUE)
    
    trend_emoji <- if (forecast$trend_direction == "upward") "📈" else "📉"
    
    HTML(paste0(
      "<strong>Forecast Summary</strong><br/>",
      "Trend: ", forecast$trend_direction, " ", trend_emoji, "<br/>",
      "Average predicted value: ", round(avg_pred, 3), "<br/>",
      "Predicted range: ", round(min_pred, 3), " to ", round(max_pred, 3), "<br/>",
      "Trend rate: ", round(forecast$trend_value, 4), " per period"
    ))
  })

  output$message <- renderText({ user_message() })
  output$preview <- renderTable({ head(filtered_data(), 10) })

  output$dataPlot <- renderPlot({
    df <- filtered_data()
    pd <- plot_data()
    insights <- ai_insights_raw()
    clusters <- cluster_info()$labels
    anomalies <- anomaly_zscore()$row_flags

    palette_cols <- c("#1f77b4", "#2ca02c", "#ff7f0e", "#9467bd", "#d62728")
    base_col <- rep("steelblue", nrow(df))
    cluster_idx <- !is.na(clusters)
    if (any(cluster_idx)) {
      base_col[cluster_idx] <- palette_cols[((clusters[cluster_idx] - 1) %% length(palette_cols)) + 1]
    }

    plot(pd$x, pd$y, xlab = input$xcol, ylab = input$ycol,
         main = paste("Filtered plot of", input$ycol, "vs", input$xcol),
         pch = 19, col = base_col)

    fit <- regression_model()
    if (!is.null(fit)) abline(fit, col = "darkgreen", lwd = 2)

    if (length(anomalies) == nrow(df) && any(anomalies, na.rm = TRUE)) {
      points(pd$x[anomalies], pd$y[anomalies], pch = 1, cex = 1.4, lwd = 1.5, col = "black")
    }

    if (is.null(insights)) return()

    mode <- selected_highlight()
    if (identical(mode, "correlation")) {
      pair <- insights$strongest_pair
      pair_ok <- length(pair) == 2 && !any(is.na(pair))
      current_pair <- c(input$xcol, input$ycol)
      if (pair_ok && (all(current_pair == pair) || all(current_pair == rev(pair)))) {
        idx <- !is.na(pd$x) & !is.na(pd$y)
        points(pd$x[idx], pd$y[idx], pch = 19, col = "red")
      }
    }

    if (identical(mode, "variance")) {
      hv_col <- insights$highest_variance_column
      if (!is.na(hv_col) && hv_col %in% c(input$xcol, input$ycol) && is.numeric(df[[hv_col]])) {
        z <- abs(scale(df[[hv_col]])); z[is.na(z)] <- 0
        idx <- as.vector(z >= stats::quantile(z, 0.9, na.rm = TRUE)); idx[is.na(idx)] <- FALSE
        points(pd$x[idx], pd$y[idx], pch = 17, col = "darkorange", cex = 1.1)
      }
    }

    if (identical(mode, "outlier")) {
      outlier_cols <- names(insights$outlier_counts[insights$outlier_counts >= 1])
      chosen <- intersect(outlier_cols, c(input$xcol, input$ycol))
      if (length(chosen) > 0 && is.numeric(df[[chosen[1]]])) {
        target <- df[[chosen[1]]]
        q1 <- stats::quantile(target, 0.25, na.rm = TRUE, names = FALSE)
        q3 <- stats::quantile(target, 0.75, na.rm = TRUE, names = FALSE)
        iqr_value <- q3 - q1
        idx <- (target < q1 - 1.5 * iqr_value | target > q3 + 1.5 * iqr_value)
        idx[is.na(idx)] <- FALSE
        points(pd$x[idx], pd$y[idx], pch = 8, col = "purple", cex = 1.2)
      }
    }
  })

  output$summaryStats <- renderTable({ summary_stats() })
  output$aiInsights <- renderText({ req(ai_insights_text()); ai_insights_text() })
  output$ai_highlight <- renderUI({
    req(selected_highlight())

    if (selected_highlight() == "correlation") {
      insight <- strongest_correlation_insight()

      if (is.null(insight)) {
        div(
          strong("Strongest Relationship Insight:"),
          "No reliable strongest relationship could be determined."
        )
      } else {
        div(
          strong("Strongest Relationship Insight:"),
          insight$interpretation
        )
      }
    } else if (selected_highlight() == "variance") {
      var_result <- variance_insight()

      if (is.null(var_result)) {
        div(
          strong("Variability Insight:"),
          "No numeric columns were available to assess variability."
        )
      } else {
        div(
          strong("Variability Insight:"),
          var_result$interpretation
        )
      }
    } else if (selected_highlight() == "outlier") {
      outlier_result <- outlier_insight()

      if (is.null(outlier_result)) {
        div(
          strong("Anomaly Insight:"),
          "No numeric columns were available to assess anomalies."
        )
      } else {
        div(
          strong("Anomaly Insight:"),
          outlier_result$interpretation
        )
      }
    }
  })

  output$cor_heatmap <- renderPlot({

    cm <- cor_matrix()
    req(cm)

    highlight_pair <- NULL

    if (!is.null(selected_highlight()) &&
        selected_highlight() == "correlation") {

      temp_cm <- cm
      diag(temp_cm) <- 0
      max_idx <- which(abs(temp_cm) == max(abs(temp_cm)), arr.ind = TRUE)[1,]
      highlight_pair <- max_idx
    }

    heatmap(
      cm,
      symm = TRUE,
      col = colorRampPalette(c("blue", "white", "red"))(20),
      margins = c(8, 8)
    )

  })

  output$download_report <- downloadHandler(
    filename = function() {
      paste("AI_Insight_Report_", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      df <- filtered_data()
      corr_insight <- strongest_correlation_insight()
      var_result <- variance_insight()
      outlier_result <- outlier_insight()
      health <- dataset_health()
      profile <- dataset_profile_obj()
      forecast <- forecast_results()

      correlation_text <- if (is.null(corr_insight)) "No reliable strongest relationship could be determined." else corr_insight$interpretation
      variance_text <- if (is.null(var_result)) "No numeric columns were available to assess variability." else var_result$interpretation
      outlier_text <- if (is.null(outlier_result)) "No numeric columns were available to assess anomalies." else outlier_result$interpretation
      health_score <- health$total_score
      health_comment <- health$comment

      pdf(file, width = 8.27, height = 11.69)  # A4 size
      on.exit(dev.off(), add = TRUE)
      par(mar = c(1,1,1,1))
      plot.new()

      y <- 0.95

      add_line <- function(text, size=1, bold=FALSE){
        font_type <- ifelse(bold, 2, 1)
        text(0.05, y, text, adj=0, cex=size, font=font_type)
        y <<- y - 0.05
      }

      add_line("INSIGHTFORGE AI REPORT", 1.8, TRUE)
      add_line(paste("Generated:", Sys.time()))
      add_line(" ")

      add_line("DATASET OVERVIEW", 1.3, TRUE)
      add_line(paste("Rows:", nrow(df)))
      add_line(paste("Columns:", ncol(df)))
      if (!is.null(profile)) {
        add_line(paste("Numeric Columns:", length(profile$numeric_cols)))
        missing_total <- sum(profile$missing_counts)
        add_line(paste("Missing Values (Total):", missing_total))
      }
      add_line(" ")

      add_line("CORRELATION INTELLIGENCE", 1.3, TRUE)
      add_line(correlation_text)
      add_line(" ")

      add_line("VARIANCE ANALYSIS", 1.3, TRUE)
      add_line(variance_text)
      add_line(" ")

      add_line("ANOMALY DETECTION", 1.3, TRUE)
      add_line(outlier_text)
      add_line(" ")

      add_line("DATASET HEALTH SCORE", 1.3, TRUE)
      add_line(paste("Score:", health_score, "/ 100"))
      add_line(health_comment)
      add_line(" ")

      # NEW: FORECASTING SECTION
      if (!is.null(forecast)) {
        add_line("TIME-SERIES FORECASTING", 1.3, TRUE)
        add_line(paste("Target Variable:", input$forecast_target))
        add_line(paste("Trend Direction:", forecast$trend_direction))
        add_line(paste("Trend Rate:", round(forecast$trend_value, 4), "per period"))
        avg_pred <- mean(forecast$predicted, na.rm = TRUE)
        min_pred <- min(forecast$predicted, na.rm = TRUE)
        max_pred <- max(forecast$predicted, na.rm = TRUE)
        add_line(paste("Predicted Average:", round(avg_pred, 2)))
        add_line(paste("Predicted Range:", round(min_pred, 2), "to", round(max_pred, 2)))
        add_line(" ")
      }

      add_line("END OF REPORT", 1.2, TRUE)
    }
  )

  output$download_filtered <- downloadHandler(
    filename = function() paste0("filtered_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content = function(file) write.csv(filtered_data(), file, row.names = FALSE)
  )

  output$download_plot <- downloadHandler(
    filename = function() paste0("filtered_plot_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png"),
    content = function(file) {
      df <- filtered_data()
      pd <- plot_data()
      insights <- ai_insights_raw()
      clusters <- cluster_info()$labels
      anomalies <- anomaly_zscore()$row_flags

      png(filename = file, width = 1000, height = 700, res = 120)

      palette_cols <- c("#1f77b4", "#2ca02c", "#ff7f0e", "#9467bd", "#d62728")
      base_col <- rep("steelblue", nrow(df))
      cluster_idx <- !is.na(clusters)
      if (any(cluster_idx)) {
        base_col[cluster_idx] <- palette_cols[((clusters[cluster_idx] - 1) %% length(palette_cols)) + 1]
      }

      plot(pd$x, pd$y, xlab = input$xcol, ylab = input$ycol,
           main = paste("Filtered plot of", input$ycol, "vs", input$xcol),
           pch = 19, col = base_col)

      fit <- regression_model()
      if (!is.null(fit)) abline(fit, col = "darkgreen", lwd = 2)
      if (length(anomalies) == nrow(df) && any(anomalies, na.rm = TRUE)) {
        points(pd$x[anomalies], pd$y[anomalies], pch = 1, cex = 1.4, lwd = 1.5, col = "black")
      }

      if (!is.null(insights)) {
        mode <- selected_highlight()
        if (identical(mode, "correlation")) {
          pair <- insights$strongest_pair
          pair_ok <- length(pair) == 2 && !any(is.na(pair))
          current_pair <- c(input$xcol, input$ycol)
          if (pair_ok && (all(current_pair == pair) || all(current_pair == rev(pair)))) {
            idx <- !is.na(pd$x) & !is.na(pd$y)
            points(pd$x[idx], pd$y[idx], pch = 19, col = "red")
          }
        }
        if (identical(mode, "variance")) {
          hv_col <- insights$highest_variance_column
          if (!is.na(hv_col) && hv_col %in% c(input$xcol, input$ycol) && is.numeric(df[[hv_col]])) {
            z <- abs(scale(df[[hv_col]])); z[is.na(z)] <- 0
            idx <- as.vector(z >= stats::quantile(z, 0.9, na.rm = TRUE)); idx[is.na(idx)] <- FALSE
            points(pd$x[idx], pd$y[idx], pch = 17, col = "darkorange", cex = 1.1)
          }
        }
        if (identical(mode, "outlier")) {
          outlier_cols <- names(insights$outlier_counts[insights$outlier_counts >= 1])
          chosen <- intersect(outlier_cols, c(input$xcol, input$ycol))
          if (length(chosen) > 0 && is.numeric(df[[chosen[1]]])) {
            target <- df[[chosen[1]]]
            q1 <- stats::quantile(target, 0.25, na.rm = TRUE, names = FALSE)
            q3 <- stats::quantile(target, 0.75, na.rm = TRUE, names = FALSE)
            iqr_value <- q3 - q1
            idx <- (target < q1 - 1.5 * iqr_value | target > q3 + 1.5 * iqr_value)
            idx[is.na(idx)] <- FALSE
            points(pd$x[idx], pd$y[idx], pch = 8, col = "purple", cex = 1.2)
          }
        }
      }

      dev.off()
    }
  )
}

# ---- App entrypoint (Shiny Server handles host/port binding) ----
shinyApp(ui, server)
