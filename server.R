# server.R
# Purpose: Connect UI controls to simulation functions and render enhanced,
# interactive visual outputs for the Dynamic System Risk Simulator.

library(shiny)
library(plotly)

server <- function(input, output, session) {
  # Keep shock node selector valid for the currently selected node count.
  observeEvent(input$n_nodes, {
    updateSliderInput(
      session = session,
      inputId = "shock_node",
      min = 1,
      max = input$n_nodes,
      value = min(input$shock_node, input$n_nodes)
    )
  }, ignoreInit = FALSE)

  # Keep histogram timestep selector aligned to current simulation horizon.
  observeEvent(input$timesteps, {
    updateSliderInput(
      session = session,
      inputId = "hist_timestep",
      min = 1,
      max = input$timesteps,
      value = min(input$hist_timestep, input$timesteps)
    )
  }, ignoreInit = FALSE)

  # Trigger used for both explicit button-run and slider-driven live updates.
  # This supports real-time graph refresh while keeping a clear run action.
  run_trigger <- reactiveVal(0)

  observeEvent(input$run_sim, {
    run_trigger(run_trigger() + 1)
  }, ignoreInit = TRUE)

  observeEvent(
    list(input$n_nodes, input$edge_density, input$shock_node, input$threshold, input$timesteps),
    {
      run_trigger(run_trigger() + 1)
    },
    ignoreInit = FALSE
  )

  # Single simulation reactive that all outputs depend on.
  # Centralizing this avoids duplicated compute across plots/tables.
  sim_results <- eventReactive(run_trigger(), {
    # 1) Generate network from selected controls.
    network_data <- generate_network(
      n_nodes = input$n_nodes,
      edge_density = input$edge_density,
      min_capital = 100,
      max_capital = 1000,
      min_risk = 0,
      max_risk = 1
    )

    # 2) Run simulation using the generated network and user settings.
    simulation <- run_simulation(
      nodes_df = network_data$nodes_df,
      edges_df = network_data$edges_df,
      shock_node = input$shock_node,
      threshold = input$threshold,
      timesteps = input$timesteps
    )

    # 3) Prepare final node states for network coloring + tooltips.
    final_nodes <- simulation$states_by_timestep[[length(simulation$states_by_timestep)]] %>%
      dplyr::mutate(
        # Color-mapping logic:
        # healthy -> green, stressed -> yellow, default -> red.
        display_status = dplyr::case_when(
          .data$status == "default" ~ "default",
          .data$capital < input$threshold ~ "stressed",
          TRUE ~ "healthy"
        ),
        # Tooltip fields used by ggplotly for hover interactivity.
        tooltip_text = paste0(
          "Node ID: ", .data$id,
          "<br>Capital: ", round(.data$capital, 2),
          "<br>Risk level: ", round(.data$risk_level, 3),
          "<br>Status: ", .data$display_status
        )
      )

    defaults_by_timestep <- simulation$states_long %>%
      dplyr::group_by(.data$timestep) %>%
      dplyr::summarise(n_defaults = sum(.data$status == "default"), .groups = "drop")

    status_counts <- simulation$states_long %>%
      dplyr::mutate(
        display_status = dplyr::case_when(
          .data$status == "default" ~ "default",
          .data$capital < input$threshold ~ "stressed",
          TRUE ~ "healthy"
        )
      ) %>%
      dplyr::count(.data$timestep, .data$display_status, name = "n_nodes") %>%
      dplyr::arrange(.data$timestep, .data$display_status)

    list(
      network = network_data,
      simulation = simulation,
      final_nodes = final_nodes,
      defaults_by_timestep = defaults_by_timestep,
      status_counts = status_counts
    )
  })

  # Interactive network graph:
  # - Node colors follow display_status mapping.
  # - Edge color gradient reflects exposure_weight.
  # - Hover tooltips show ID/capital/risk/status.
  output$network_plot <- renderPlotly({
    req(sim_results())

    graph_obj <- igraph::graph_from_data_frame(
      d = sim_results()$network$edges_df,
      vertices = sim_results()$final_nodes,
      directed = TRUE
    )

    network_gg <- ggraph::ggraph(graph_obj, layout = "fr") +
      ggraph::geom_edge_link(
        ggplot2::aes(edge_colour = .data$exposure_weight),
        alpha = 0.5
      ) +
      ggraph::scale_edge_colour_gradient(low = "#c6dbef", high = "#08519c") +
      ggraph::geom_node_point(
        ggplot2::aes(color = .data$display_status, text = .data$tooltip_text),
        size = 5
      ) +
      ggraph::geom_node_text(ggplot2::aes(label = .data$id), size = 3, vjust = -1) +
      ggplot2::scale_color_manual(
        values = c(healthy = "#2ca25f", stressed = "#ffdd00", default = "#de2d26")
      ) +
      ggplot2::labs(color = "Node Status", edge_colour = "Exposure") +
      ggplot2::theme_void()

    plotly::ggplotly(network_gg, tooltip = "text")
  })

  # Line chart showing total defaults over time.
  output$defaults_line_plot <- renderPlot({
    req(sim_results())

    ggplot2::ggplot(sim_results()$defaults_by_timestep, ggplot2::aes(x = .data$timestep, y = .data$n_defaults)) +
      ggplot2::geom_line(color = "#de2d26", linewidth = 1.1) +
      ggplot2::geom_point(color = "#de2d26", size = 2) +
      ggplot2::scale_x_continuous(breaks = seq_len(input$timesteps)) +
      ggplot2::labs(
        title = "Number of Defaults Over Time",
        x = "Timestep",
        y = "Defaulted Nodes"
      ) +
      ggplot2::theme_minimal()
  })

  # Histogram of capital distribution for a selected timestep.
  output$capital_hist_plot <- renderPlot({
    req(sim_results())

    hist_df <- sim_results()$simulation$states_long %>%
      dplyr::filter(.data$timestep == input$hist_timestep)

    ggplot2::ggplot(hist_df, ggplot2::aes(x = .data$capital)) +
      ggplot2::geom_histogram(bins = 20, fill = "#3182bd", color = "white", alpha = 0.85) +
      ggplot2::labs(
        title = paste("Capital Distribution at Timestep", input$hist_timestep),
        x = "Capital",
        y = "Node Count"
      ) +
      ggplot2::theme_minimal()
  })

  # Summary table for defaults per timestep.
  output$summary_table <- renderTable({
    req(sim_results())
    sim_results()$defaults_by_timestep
  })

  # Optional status count table (healthy/stressed/default by timestep).
  output$status_count_table <- renderTable({
    req(sim_results())
    sim_results()$status_counts
  })

  # Detailed node states table.
  output$node_table <- renderTable({
    req(sim_results())

    sim_results()$simulation$states_long %>%
      dplyr::mutate(
        display_status = dplyr::case_when(
          .data$status == "default" ~ "default",
          .data$capital < input$threshold ~ "stressed",
          TRUE ~ "healthy"
        )
      ) %>%
      dplyr::select(.data$timestep, .data$id, .data$capital, .data$risk_level, .data$display_status) %>%
      dplyr::arrange(.data$timestep, .data$id)
  })
}
