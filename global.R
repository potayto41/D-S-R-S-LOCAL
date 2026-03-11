# global.R
# Purpose: Load shared libraries and define reusable functions
# for the Dynamic System Risk Simulator.

library(tidyverse)
library(igraph)
library(ggraph)
library(plotly)
library(shiny)

#' Generate a random directed weighted network and node attributes.
#'
#' @param n_nodes Integer number of nodes in the network.
#' @param edge_density Numeric probability of an edge between any two nodes (0-1).
#' @param min_capital Numeric minimum starting capital per node.
#' @param max_capital Numeric maximum starting capital per node.
#' @param min_risk Numeric minimum initial risk level per node.
#' @param max_risk Numeric maximum initial risk level per node.
#' @return A list with `nodes_df` and `edges_df` data frames.
generate_network <- function(
    n_nodes,
    edge_density,
    min_capital,
    max_capital,
    min_risk,
    max_risk
) {
  # Basic input checks to keep this function safe and modular for downstream use.
  stopifnot(n_nodes > 0)
  stopifnot(edge_density >= 0, edge_density <= 1)
  stopifnot(min_capital <= max_capital)
  stopifnot(min_risk <= max_risk)

  # Build a random directed graph with no self-loops.
  # Probability of each possible directed edge is controlled by edge_density.
  graph_obj <- igraph::sample_gnp(
    n = n_nodes,
    p = edge_density,
    directed = TRUE,
    loops = FALSE
  )

  # Construct the node table with required attributes:
  # id, capital, risk_level, and status.
  nodes_df <- tibble::tibble(
    id = seq_len(n_nodes),
    capital = runif(n_nodes, min = min_capital, max = max_capital),
    risk_level = runif(n_nodes, min = min_risk, max = max_risk),
    status = "healthy"
  )

  # Extract edge endpoints from igraph and attach exposure weights.
  # exposure_weight is initialized randomly in [0, 1].
  edge_ends <- igraph::as_data_frame(graph_obj, what = "edges")

  if (nrow(edge_ends) == 0) {
    # Keep a consistent schema even when no edges are generated.
    edges_df <- tibble::tibble(
      from = integer(),
      to = integer(),
      exposure_weight = numeric()
    )
  } else {
    edges_df <- tibble::as_tibble(edge_ends) %>%
      dplyr::transmute(
        from = as.integer(.data$from),
        to = as.integer(.data$to),
        exposure_weight = runif(dplyr::n(), min = 0, max = 1)
      )
  }

  # Return node and edge data separately so simulation steps can be
  # implemented independently in later prompts.
  list(
    nodes_df = nodes_df,
    edges_df = edges_df
  )
}

#' Propagate default risk through the network until no new defaults occur.
#'
#' @param nodes_df Data frame of nodes with at least `id`, `capital`, and `status`.
#' @param edges_df Data frame of edges with `from`, `to`, and `exposure_weight`.
#' @param shock_node Integer ID of the initially defaulted node.
#' @param threshold Numeric minimum capital; nodes below this default.
#' @return Updated `nodes_df` with propagated `capital` and `status`.
propagate_risk <- function(nodes_df, edges_df, shock_node, threshold) {
  # Validate required columns to keep integration predictable.
  required_node_cols <- c("id", "capital", "status")
  required_edge_cols <- c("from", "to", "exposure_weight")

  stopifnot(all(required_node_cols %in% names(nodes_df)))
  stopifnot(all(required_edge_cols %in% names(edges_df)))
  stopifnot(length(shock_node) == 1)

  if (!(shock_node %in% nodes_df$id)) {
    stop("shock_node must exist in nodes_df$id")
  }

  # Work on a local copy so the function can be called repeatedly.
  updated_nodes <- tibble::as_tibble(nodes_df)
  updated_edges <- tibble::as_tibble(edges_df)

  # Apply the initial shock by defaulting the selected node.
  updated_nodes <- updated_nodes %>%
    dplyr::mutate(
      status = dplyr::if_else(.data$id == shock_node, "default", .data$status)
    )

  # Iteratively propagate losses from currently defaulted nodes.
  repeat {
    # Identify all nodes that are currently defaulted.
    default_ids <- updated_nodes %>%
      dplyr::filter(.data$status == "default") %>%
      dplyr::pull(.data$id)

    # Stop if there are no defaults to propagate from.
    if (length(default_ids) == 0) {
      break
    }

    # Calculate capital losses on outgoing neighbors of defaulted nodes.
    # Losses are aggregated per receiving node for this timestep.
    losses_df <- updated_edges %>%
      dplyr::filter(.data$from %in% default_ids) %>%
      dplyr::group_by(.data$to) %>%
      dplyr::summarise(loss = sum(.data$exposure_weight), .groups = "drop")

    # If no neighbors are affected, propagation has converged.
    if (nrow(losses_df) == 0) {
      break
    }

    # Apply losses only to nodes that are not already defaulted.
    updated_nodes <- updated_nodes %>%
      dplyr::left_join(losses_df, by = c("id" = "to")) %>%
      dplyr::mutate(
        loss = tidyr::replace_na(.data$loss, 0),
        capital = dplyr::if_else(
          .data$status == "default",
          .data$capital,
          .data$capital - .data$loss
        )
      ) %>%
      dplyr::select(-.data$loss)

    # Promote any newly undercapitalized, non-default nodes to default.
    prev_default_ids <- default_ids
    updated_nodes <- updated_nodes %>%
      dplyr::mutate(
        status = dplyr::if_else(
          .data$status != "default" & .data$capital < threshold,
          "default",
          .data$status
        )
      )

    # Stop when no new defaults were added in this timestep.
    new_default_ids <- updated_nodes %>%
      dplyr::filter(.data$status == "default") %>%
      dplyr::pull(.data$id)

    if (length(setdiff(new_default_ids, prev_default_ids)) == 0) {
      break
    }
  }

  # Return the updated node table for use in iterative simulations.
  updated_nodes
}

#' Run a multi-step risk simulation and capture node states over time.
#'
#' @param nodes_df Data frame of nodes from `generate_network()`.
#' @param edges_df Data frame of edges from `generate_network()`.
#' @param shock_node Integer ID of the initially shocked node.
#' @param threshold Numeric minimum capital before a node defaults.
#' @param timesteps Integer number of simulation steps to run.
#' @return A list with:
#'   - `states_by_timestep`: named list of node tables for each step
#'   - `states_long`: stacked node states across timesteps for plotting
run_simulation <- function(nodes_df, edges_df, shock_node, threshold, timesteps) {
  # Validate simulation inputs for predictable behavior in Shiny.
  stopifnot(timesteps >= 1)
  stopifnot(length(shock_node) == 1)

  # Work on local copies so repeated calls do not mutate caller objects.
  current_nodes <- tibble::as_tibble(nodes_df)
  edges_df <- tibble::as_tibble(edges_df)

  # Pre-allocate a list for efficient storage up to moderate network sizes.
  states_by_timestep <- vector(mode = "list", length = timesteps)

  # Execute timestep loop.
  for (step_idx in seq_len(timesteps)) {
    # Apply risk propagation each step.
    # At step 1, this applies the initial shock; on later steps, it continues
    # from the latest node state and captures any further changes.
    current_nodes <- propagate_risk(
      nodes_df = current_nodes,
      edges_df = edges_df,
      shock_node = shock_node,
      threshold = threshold
    )

    # Store a snapshot for this timestep.
    states_by_timestep[[step_idx]] <- current_nodes
  }

  # Name each snapshot for easier downstream access in the server layer.
  names(states_by_timestep) <- paste0("t", seq_len(timesteps))

  # Build a long-format table ready for visualization (status/capital over time).
  states_long <- purrr::imap_dfr(
    states_by_timestep,
    ~ dplyr::mutate(.x, timestep = as.integer(stringr::str_remove(.y, "^t")))
  ) %>%
    dplyr::relocate(.data$timestep, .before = .data$id)

  # Return structured outputs for plotting and summary views.
  list(
    states_by_timestep = states_by_timestep,
    states_long = states_long
  )
}

#' Visualize a network and associated risk values.
#'
#' @param network A network object.
#' @param risk_state Optional risk values for nodes.
#' @return Placeholder visualization object (to be implemented).
visualize_network <- function(network, risk_state = NULL) {
  # TODO: Implement network visualization logic.
  NULL
}
