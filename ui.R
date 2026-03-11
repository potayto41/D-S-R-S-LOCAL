# ui.R
# Purpose: Define enhanced Shiny UI for configuring, running, and exploring
# simulation outputs in the Dynamic System Risk Simulator.

library(shiny)
library(plotly)

ui <- fluidPage(
  titlePanel("Dynamic System Risk Simulator"),
  sidebarLayout(
    sidebarPanel(
      h4("Simulation Controls"),
      sliderInput("n_nodes", "Number of Nodes", min = 5, max = 100, value = 30, step = 1),
      sliderInput("edge_density", "Edge Density", min = 0, max = 1, value = 0.10, step = 0.01),
      sliderInput("shock_node", "Initial Shock Node (ID)", min = 1, max = 30, value = 1, step = 1),
      sliderInput("threshold", "Default Threshold", min = 0, max = 1000, value = 150, step = 10),
      sliderInput("timesteps", "Timesteps", min = 1, max = 20, value = 5, step = 1),
      actionButton("run_sim", "Run Simulation"),
      tags$hr(),
      # Select timestep used for the capital histogram view.
      sliderInput("hist_timestep", "Histogram Timestep", min = 1, max = 5, value = 5, step = 1)
    ),
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Network",
          br(),
          # Interactive network graph with hover tooltips.
          plotlyOutput("network_plot", height = "560px")
        ),
        tabPanel(
          "Trends",
          br(),
          plotOutput("defaults_line_plot", height = "300px"),
          br(),
          plotOutput("capital_hist_plot", height = "300px")
        ),
        tabPanel(
          "Tables",
          br(),
          h4("Defaults by Timestep"),
          tableOutput("summary_table"),
          h4("Status Counts by Timestep"),
          tableOutput("status_count_table"),
          h4("Node State Table"),
          tableOutput("node_table")
        )
      )
    )
  )
)
