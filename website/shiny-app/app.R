library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(jsonlite)
library(leaflet)
library(DT)
library(plotly)

# ── Law data ──────────────────────────────────────────────────────────────────

laws_raw <- fromJSON("data/presumptive_laws.json", simplifyVector = TRUE)
laws_raw$presumption_exists                   <- as.logical(laws_raw$presumption_exists)
laws_raw$rebuttable                           <- as.logical(laws_raw$rebuttable)
laws_raw$tobacco_exclusion                    <- as.logical(laws_raw$tobacco_exclusion)
laws_raw$discovery_during_employment_required <- as.logical(laws_raw$discovery_during_employment_required)
laws_raw$years_service_required               <- suppressWarnings(as.integer(laws_raw$years_service_required))
laws_raw$post_termination_months              <- suppressWarnings(as.integer(laws_raw$post_termination_months))

# ── Map geometry ──────────────────────────────────────────────────────────────

states_poly     <- readRDS("data/us_states_shifted.rds")
poly_base_names <- gsub(":.*", "", states_poly$names)

# ── Reference lookups ─────────────────────────────────────────────────────────

type_priority <- c(statute = 4L, EO = 3L, expired = 2L, none = 1L)

status_labels <- c(
  statute = "Active statute",
  EO      = "Executive order",
  expired = "Expired / lapsed",
  none    = "No law found"
)

occ_clrs <- c(
  "#e8e8e8", "#fee5d9", "#fcbba1", "#fc9272",
  "#fb6a4a", "#de2d26", "#a50f15"
)

status_clrs <- c(
  statute = "#1d6fa5",
  EO      = "#e07b00",
  expired = "#b0b0b0",
  none    = "#999999"
)

# "all" must be first so it becomes the default selection
conditions <- c(
  "All conditions"         = "all",
  "Cancer"                 = "cancer",
  "Cardiovascular Disease" = "cardiovascular",
  "Respiratory Disease"    = "respiratory",
  "Infectious Disease"     = "infectious",
  "Mental Health / PTSD"   = "mental",
  "Other"                  = "other"
)

responder_choices <- c(
  "Firefighter (career)"    = "firefighter",
  "Firefighter (volunteer)" = "firefighter_volunteer",
  "EMT / Paramedic"         = "emt_paramedic",
  "Law Enforcement"         = "law_enforcement",
  "Corrections"             = "corrections"
)

responder_labels <- c(
  firefighter           = "Firefighter (career)",
  firefighter_volunteer = "Firefighter (volunteer)",
  emt_paramedic         = "EMT / Paramedic",
  law_enforcement       = "Law enforcement",
  corrections           = "Corrections"
)

state_url_lu <- laws_raw |> distinct(state_name, state, iaff_url)

# ── UpSet helpers ─────────────────────────────────────────────────────────────

GROUPS <- c("firefighter", "firefighter_volunteer", "emt_paramedic",
             "law_enforcement", "corrections")
GROUP_LABELS <- c("Firefighter", "FF Volunteer", "EMS / Paramedic",
                   "Law Enforcement", "Corrections")

# Condition groups — used when occupation is fixed and conditions are the rows
COND_GROUPS <- c("cancer", "cardiovascular", "respiratory",
                  "infectious", "mental", "other")
COND_LABELS <- c("Cancer", "Cardiovascular", "Respiratory",
                  "Infectious Disease", "Mental Health/PTSD", "Other")

compute_upset_data <- function(df, condition_val) {
  covered <- if (condition_val == "all") {
    df |> filter(presumption_exists == TRUE) |>
      select(state, responder_type) |> distinct()
  } else {
    df |> filter(condition_category == condition_val, presumption_exists == TRUE) |>
      select(state, responder_type) |> distinct()
  }

  if (nrow(covered) == 0) return(NULL)

  wide <- covered |>
    mutate(val = TRUE) |>
    pivot_wider(
      names_from  = responder_type,
      values_from = val,
      values_fill = FALSE,
      values_fn   = list(val = any)
    )
  for (g in GROUPS) if (!g %in% names(wide)) wide[[g]] <- FALSE
  wide <- wide[, c("state", GROUPS)]

  int_df <- wide |>
    group_by(across(all_of(GROUPS))) |>
    summarise(n = n(), states = list(sort(state)), .groups = "drop") |>
    arrange(desc(n))

  set_n <- sapply(GROUPS, function(g) sum(wide[[g]]))

  list(int_df = int_df, set_n = set_n)
}

# Condition-first UpSet data: occupation is the filter, conditions are the rows
compute_upset_data_cond <- function(df, occupation_val) {
  covered <- if (occupation_val == "all") {
    df |> filter(presumption_exists == TRUE) |>
      select(state, condition_category) |> distinct()
  } else {
    df |> filter(responder_type == occupation_val, presumption_exists == TRUE) |>
      select(state, condition_category) |> distinct()
  }
  if (nrow(covered) == 0) return(NULL)

  wide <- covered |>
    mutate(val = TRUE) |>
    pivot_wider(
      names_from  = condition_category,
      values_from = val,
      values_fill = FALSE,
      values_fn   = list(val = any)
    )
  for (g in COND_GROUPS) if (!g %in% names(wide)) wide[[g]] <- FALSE
  wide <- wide[, c("state", COND_GROUPS)]

  int_df <- wide |>
    group_by(across(all_of(COND_GROUPS))) |>
    summarise(n = n(), states = list(sort(state)), .groups = "drop") |>
    arrange(desc(n))

  set_n <- sapply(COND_GROUPS, function(g) sum(wide[[g]]))
  list(int_df = int_df, set_n = set_n)
}

# Compute filled dot data — groups param selects which column set to use
upset_dot_filled <- function(int_df, groups) {
  n_int <- nrow(int_df)
  n_grp <- length(groups)
  expand.grid(x = seq_len(n_int), y = seq_len(n_grp), stringsAsFactors = FALSE) |>
    as_tibble() |>
    mutate(
      grp    = groups[y],
      filled = mapply(function(xi, grp) isTRUE(int_df[[grp]][xi]), x, grp)
    ) |>
    filter(filled)
}

# Compute line segment data
upset_lines <- function(int_df, groups) {
  n_int <- nrow(int_df)
  n_grp <- length(groups)
  expand.grid(x = seq_len(n_int), y = seq_len(n_grp), stringsAsFactors = FALSE) |>
    as_tibble() |>
    mutate(
      grp    = groups[y],
      filled = mapply(function(xi, grp) isTRUE(int_df[[grp]][xi]), x, grp)
    ) |>
    filter(filled) |>
    group_by(x) |>
    summarise(y0 = min(y), y1 = max(y), .groups = "drop") |>
    filter(y1 > y0)
}

make_upset_plot <- function(upset_data, groups, group_labels, source_id = "upset_plot") {

  if (is.null(upset_data)) {
    return(
      plot_ly(source = source_id) |>
        add_annotations(
          text = "No coverage found for this condition",
          x = 0.5, y = 0.5, xref = "paper", yref = "paper",
          showarrow = FALSE, font = list(size = 12, color = "#888")
        ) |>
        layout(paper_bgcolor = "white",
               xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
    )
  }

  int_df  <- upset_data$int_df
  set_n   <- upset_data$set_n
  n_grp   <- length(groups)
  n_int   <- nrow(int_df)
  x_pos   <- seq_len(n_int)
  y_pos   <- seq_len(n_grp)

  # Dot grid
  all_dots <- expand.grid(x = x_pos, y = y_pos, stringsAsFactors = FALSE) |>
    as_tibble() |>
    mutate(grp    = groups[y],
           filled = mapply(function(xi, g) isTRUE(int_df[[g]][xi]), x, grp))

  # Connecting lines as trace data (NA-separated segments so they render
  # BELOW the dot traces — shapes don't reliably stay below traces in
  # multi-axis plotly figures)
  line_df <- upset_lines(int_df, groups)
  n_segs  <- nrow(line_df)
  if (n_segs > 0) {
    ln_x <- as.numeric(rbind(line_df$x,  line_df$x,  rep(NA_real_, n_segs)))
    ln_y <- as.numeric(rbind(line_df$y0, line_df$y1, rep(NA_real_, n_segs)))
  } else {
    ln_x <- NA_real_; ln_y <- NA_real_
  }

  # Alternating row strips (shapes — layer="below" so they render UNDER all traces)
  alt_fill <- c("#f4f4f4", "white", "#f4f4f4", "white", "#f4f4f4")
  strip_shapes <- lapply(seq_len(n_grp), function(i) {
    list(type      = "rect",
         x0        = 0.22, x1 = 1.0,     # paper coords: from after set-size bars to right edge
         y0        = i - 0.5, y1 = i + 0.5,
         xref      = "paper", yref = "y",
         fillcolor = alt_fill[i],
         layer     = "below",
         opacity   = 1,
         line      = list(width = 0))
  })

  # Group label annotations in the gap between set-size bars and dot matrix
  group_annots <- lapply(seq_len(n_grp), function(i) {
    list(x = 0.42, y = i, text = group_labels[i],
         xref = "paper", yref = "y",
         showarrow = FALSE, xanchor = "right", yanchor = "middle",
         font = list(size = 10, color = "#333"), align = "right")
  })

  # customdata on intersection bars carries comma-sep state list
  bar_customdata <- sapply(int_df$states, paste, collapse = ",")

  # Trace index map (0-indexed for plotlyProxy):
  #   0 = bg_lines    (connecting lines, default/dim colour)
  #   1 = hl_line     (single highlighted line, column hover only)
  #   2 = empty_dots
  #   3 = filled_dots
  #   4 = int_bars    ← hover target (curveNumber 4)
  #   5 = set_bars    ← click target (curveNumber 5)

  plot_ly(source = source_id) |>

    # Trace 0 — background connecting lines (all segments; colour updated by proxy)
    add_lines(
      x = ln_x, y = ln_y,
      line       = list(color = "#2171b5", width = 3),
      xaxis = "x", yaxis = "y",
      hoverinfo = "none", showlegend = FALSE, name = "bg_lines"
    ) |>

    # Trace 1 — highlighted line (initially invisible NA; populated on column hover)
    add_lines(
      x = NA_real_, y = NA_real_,
      line       = list(color = "#2171b5", width = 4),
      xaxis = "x", yaxis = "y",
      hoverinfo = "none", showlegend = FALSE, name = "hl_line"
    ) |>

    # Trace 2 — empty dots (white border so stripe/line doesn't bleed through)
    add_markers(
      data = all_dots |> filter(!filled), x = ~x, y = ~y,
      marker = list(color = "#d0d0d0", size = 12,
                    line = list(color = "white", width = 2)),
      xaxis = "x", yaxis = "y",
      hoverinfo = "none", showlegend = FALSE
    ) |>

    # Trace 3 — filled dots (colours/sizes updated by proxy on hover/select)
    add_markers(
      data = all_dots |> filter(filled), x = ~x, y = ~y,
      marker = list(color = "#2171b5", size = 16,
                    line = list(color = "white", width = 3)),
      xaxis = "x", yaxis = "y",
      hoverinfo = "none", showlegend = FALSE
    ) |>

    # Trace 4 — intersection size bars (hover target)
    add_bars(
      x = x_pos, y = int_df$n,
      customdata = bar_customdata,
      hoverinfo  = "none",
      marker = list(color = "#4292c6", line = list(color = "white", width = 0.5)),
      xaxis = "x", yaxis = "y2",
      showlegend = FALSE, name = "intersection"
    ) |>

    # Trace 5 — set size bars (click target)
    add_bars(
      x = set_n, y = y_pos, orientation = "h",
      hoverinfo = "none",
      marker = list(color = "#9ecae1"),
      xaxis = "x2", yaxis = "y3",
      showlegend = FALSE, name = "setsize"
    ) |>

    layout(
      paper_bgcolor = "white",
      plot_bgcolor  = "white",
      showlegend    = FALSE,
      autosize      = TRUE,
      shapes        = strip_shapes,   # permanent alternating strips
      annotations   = group_annots,
      bargap        = 0.25,
      margin        = list(l = 5, r = 8, t = 30, b = 25),

      xaxis = list(
        domain = c(0.44, 1.0), visible = FALSE,
        range = c(0.5, n_int + 0.5), fixedrange = TRUE
      ),

      xaxis2 = list(
        domain     = c(0, 0.20),
        autorange  = "reversed",
        showgrid   = TRUE,
        gridcolor  = "#e8e8e8",
        zeroline   = FALSE,
        tickangle  = 0,
        tickfont   = list(size = 9),
        title      = list(text = "Set size", font = list(size = 9)),
        fixedrange = TRUE
      ),

      yaxis = list(
        domain         = c(0, 0.50),
        autorange      = "reversed",
        showgrid       = FALSE,
        showticklabels = FALSE,
        showline       = FALSE,
        zeroline       = FALSE,
        title          = list(text = ""),
        fixedrange     = TRUE
      ),

      yaxis2 = list(
        domain    = c(0.60, 1.0),
        title     = list(text = "# States", font = list(size = 10)),
        showgrid  = TRUE, gridcolor = "#f0f0f0",
        rangemode = "tozero", tickfont = list(size = 9), fixedrange = TRUE
      ),

      yaxis3 = list(
        domain         = c(0, 0.50),
        autorange      = "reversed",
        showgrid       = FALSE,
        showticklabels = FALSE,
        showline       = FALSE,
        zeroline       = FALSE,
        visible        = FALSE,
        fixedrange     = TRUE
      )
    )
}

# ── Legend helper ─────────────────────────────────────────────────────────────

make_legend <- function(colors, labels) {
  items <- mapply(function(col, lbl) {
    brd <- if (col == "#e8e8e8") "border:1px solid #bbb;" else ""
    paste0('<span style="display:inline-block;width:13px;height:13px;background:', col, ';',
           brd, 'border-radius:2px;margin-right:6px;vertical-align:middle;"></span>', lbl, '<br>')
  }, colors, labels, SIMPLIFY = TRUE)
  HTML(paste0('<div style="font-size:0.82em;line-height:2.2;">', paste(items, collapse=""), '</div>'))
}

legend_occupation_html <- make_legend(
  occ_clrs,
  c("No coverage","1 condition","2 conditions","3 conditions",
    "4 conditions","5 conditions","6 conditions")
)

# ── UI ────────────────────────────────────────────────────────────────────────

ui <- fluidPage(
  theme = bs_theme(bootswatch = "cosmo"),
  tags$style(HTML(".leaflet-container { background: #cfe2f3 !important; }")),
  titlePanel("First Responder Presumptive Laws"),

  # ── Row 1: Controls (col 3) | UpSet plot / occupation legend (col 9) ──────
  # display:flex + align-items:stretch makes both columns the same height
  div(
    class = "row",
    style = "display:flex; align-items:stretch; margin-bottom:15px;",

    div(
      class = "col-sm-3",
      wellPanel(
        style = "height:100%; padding:12px; margin-bottom:0; box-sizing:border-box;",
        radioButtons("mode", "Explore by",
          choices  = c("Occupation" = "condition", "Condition" = "occupation"),
          selected = "condition", inline = TRUE
        ),
        hr(style = "margin:8px 0;"),
        conditionalPanel(
          condition = "input.mode == 'condition'",
          selectInput("condition", "Condition", choices = conditions, selected = "all"),
          tags$p(
            style = "font-size:0.82em;color:#666;margin-top:4px;",
            "Hover a bar to highlight states. Click to select a group."
          )
        ),
        conditionalPanel(
          condition = "input.mode == 'occupation'",
          selectInput("responder_type", "Occupation",
                      choices = c("All occupations" = "all", responder_choices),
                      selected = "all")
        ),
        hr(style = "margin:8px 0;"),
        tags$p(
          "Data: ",
          tags$a("IAFF Presumptive Health Initiative",
                 href   = "https://www.iaff.org/presumptive-health/",
                 target = "_blank"),
          ". Verify with a qualified attorney or your state's WC board.",
          style = "font-size:0.78em; color:#777; margin:0;"
        )
      )
    ),

    div(
      class = "col-sm-9",
      style = "display:flex; flex-direction:column;",
      # Both modes now show the UpSet plot
      div(style = "flex:1; min-height:0;",
        plotlyOutput("upset_plot", height = "100%")
      )
    )
  ),

  # ── Row 2: Tabs — Map (full width) | State Details ────────────────────────
  tabsetPanel(
    id = "main_tabs",
    tabPanel("Map",
      br(),
      leafletOutput("map", height = "520px"),
      br(),
      uiOutput("stat_cards")
    ),
    tabPanel("State Details",
      br(),
      uiOutput("table_header"),
      DTOutput("detail_table")
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  selected_state  <- reactiveVal(NULL)
  hover_states    <- reactiveVal(NULL)   # states to highlight (from bar hover)
  hover_int_idx   <- reactiveVal(NULL)   # which intersection column is hovered (1-indexed)
  selected_group   <- reactiveVal(NULL)   # states to highlight (from set-size bar click)
  selected_grp_idx <- reactiveVal(NULL)   # group row selected via set-size bar (1-indexed)
  hover_grp_idx    <- reactiveVal(NULL)   # which set-size bar row is hovered (transient)
  selected_int_idx    <- reactiveVal(NULL)   # intersection column selected (1-indexed)
  selected_int_states <- reactiveVal(NULL)   # states in selected intersection

  # Reset everything on mode / filter change
  observeEvent(list(input$mode, input$condition, input$responder_type), {
    selected_state(NULL)
    hover_states(NULL)
    hover_int_idx(NULL)
    selected_group(NULL)
    selected_grp_idx(NULL)
    hover_grp_idx(NULL)
    selected_int_idx(NULL)
    selected_int_states(NULL)
  }, ignoreInit = TRUE)

  # ── Active groups (routes to occupation or condition row-set) ───────────────
  # "condition" mode internally = Occupation UpSet (rows = occupations)
  # "occupation" mode internally = Condition  UpSet (rows = conditions)
  active_groups_r <- reactive({
    if (input$mode == "condition") GROUPS else COND_GROUPS
  })
  active_labels_r <- reactive({
    if (input$mode == "condition") GROUP_LABELS else COND_LABELS
  })

  upset_data_r <- reactive({
    if (input$mode == "condition") {
      compute_upset_data(laws_raw, input$condition)
    } else {
      req(input$responder_type)
      compute_upset_data_cond(laws_raw, input$responder_type)
    }
  })

  # Condition label (handles "all")
  cond_label_r <- reactive({
    if (input$condition == "all") "All conditions"
    else names(conditions)[conditions == input$condition]
  })

  # Best status per state (popup) — not used in "all" mode
  best_per_state_cond <- reactive({
    req(input$mode == "condition", input$condition != "all")
    laws_raw |>
      filter(condition_category == input$condition) |>
      mutate(priority = type_priority[presumption_type]) |>
      group_by(state, state_name) |>
      slice_max(priority, n = 1, with_ties = FALSE) |>
      ungroup()
  })

  # Covered occupations per state (popup) — not used in "all" mode
  occs_per_state_cond <- reactive({
    req(input$mode == "condition", input$condition != "all")
    laws_raw |>
      filter(condition_category == input$condition, presumption_exists == TRUE) |>
      mutate(resp_label = responder_labels[responder_type]) |>
      group_by(state) |>
      summarise(
        covered_groups   = paste(sort(unique(resp_label)), collapse = ", "),
        min_svc_yrs      = suppressWarnings(min(years_service_required, na.rm = TRUE)),
        max_post_term_mo = suppressWarnings(max(post_termination_months, na.rm = TRUE)),
        .groups = "drop"
      ) |>
      mutate(
        min_svc_yrs      = ifelse(is.infinite(min_svc_yrs),      NA_real_, min_svc_yrs),
        max_post_term_mo = ifelse(is.infinite(max_post_term_mo), NA_real_, max_post_term_mo)
      )
  })

  map_data_cond <- reactive({
    req(input$mode == "condition")
    if (input$condition == "all") {
      # "All conditions": popup summarises breadth of coverage
      laws_raw |>
        filter(presumption_exists == TRUE) |>
        group_by(state, state_name) |>
        summarise(
          n_conditions = n_distinct(condition_category),
          grp_list     = paste(sort(unique(responder_labels[responder_type])), collapse = ", "),
          .groups = "drop"
        ) |>
        mutate(
          popup_html = paste0(
            "<b style='font-size:1.05em;'>", state_name, "</b><br>",
            "<span style='color:#2171b5;font-weight:600;'>",
            n_conditions, " condition type(s) covered</span>",
            "<br><span style='color:#444;font-size:0.88em;'>", grp_list, "</span>",
            "<br><span style='color:#aaa;font-size:0.75em;font-style:italic;'>",
            "Click for full state details</span>"
          )
        )
    } else {
      best_per_state_cond() |>
        left_join(occs_per_state_cond(), by = "state") |>
        mutate(
          status_color = status_clrs[presumption_type],
          status_label = status_labels[presumption_type],
          svc_yr  = coalesce(years_service_required, min_svc_yrs),
          pt_mo   = coalesce(post_termination_months, max_post_term_mo),
          svc_str = if_else(!is.na(svc_yr), paste0(as.integer(svc_yr), " yr min service"),   NA_character_),
          pt_str  = if_else(!is.na(pt_mo),  paste0(as.integer(pt_mo),  " mo post-employment"), NA_character_),
          popup_html = paste0(
            "<b style='font-size:1.05em;'>", state_name, "</b><br>",
            "<span style='color:", status_color, ";font-weight:600;'>", status_label, "</span>",
            if_else(!is.na(covered_groups),
              paste0("<br><span style='color:#444;font-size:0.88em;'>", covered_groups, "</span>"), ""),
            if_else(!is.na(statute_citation),
              paste0("<br><span style='color:#777;font-size:0.82em;'>", statute_citation, "</span>"), ""),
            if_else(!is.na(svc_str),
              paste0("<br><span style='color:#888;font-size:0.80em;'>", svc_str, "</span>"), ""),
            if_else(!is.na(pt_str),
              paste0("<br><span style='color:#888;font-size:0.80em;'>", pt_str, "</span>"), ""),
            "<br><span style='color:#aaa;font-size:0.75em;font-style:italic;'>",
            "Click for full state details</span>"
          )
        )
    }
  })

  # ── OCCUPATION MODE ─────────────────────────────────────────────────────────

  conds_per_state_occ <- reactive({
    req(input$mode == "occupation")
    base <- laws_raw |> filter(presumption_exists == TRUE)
    if (input$responder_type != "all")
      base <- base |> filter(responder_type == input$responder_type)
    base |>
      mutate(cond_label = names(conditions)[match(condition_category, conditions)]) |>
      group_by(state, state_name) |>
      summarise(
        n_conditions     = n_distinct(condition_category),
        condition_list   = paste(sort(unique(cond_label)), collapse = ", "),
        min_svc_yrs      = suppressWarnings(min(years_service_required, na.rm = TRUE)),
        max_post_term_mo = suppressWarnings(max(post_termination_months, na.rm = TRUE)),
        .groups = "drop"
      ) |>
      mutate(
        min_svc_yrs      = ifelse(is.infinite(min_svc_yrs),      NA_real_, min_svc_yrs),
        max_post_term_mo = ifelse(is.infinite(max_post_term_mo), NA_real_, max_post_term_mo),
        fill_color       = occ_clrs[pmin(n_conditions, 6L) + 1L]
      )
  })

  map_data_occ <- reactive({
    req(input$mode == "occupation")
    conds_per_state_occ() |>
      mutate(
        svc_str = if_else(!is.na(min_svc_yrs),
          paste0(as.integer(min_svc_yrs), " yr min service"), NA_character_),
        pt_str  = if_else(!is.na(max_post_term_mo),
          paste0(as.integer(max_post_term_mo), " mo post-employment"), NA_character_),
        popup_html = paste0(
          "<b style='font-size:1.05em;'>", state_name, "</b><br>",
          "<span style='color:", fill_color, ";font-weight:600;'>",
          n_conditions, " condition", ifelse(n_conditions == 1L, "", "s"), " covered</span>",
          "<br><span style='color:#444;font-size:0.88em;'>", condition_list, "</span>",
          if_else(!is.na(svc_str),
            paste0("<br><span style='color:#888;font-size:0.80em;'>", svc_str, "</span>"), ""),
          if_else(!is.na(pt_str),
            paste0("<br><span style='color:#888;font-size:0.80em;'>", pt_str, "</span>"), ""),
          "<br><span style='color:#aaa;font-size:0.75em;font-style:italic;'>",
          "Click for full state details</span>"
        )
      )
  })

  # ── Popup vectors ────────────────────────────────────────────────────────────

  poly_popups <- reactive({
    df <- if (input$mode == "condition") map_data_cond() else map_data_occ()
    vapply(poly_base_names, function(abb) {
      sname <- laws_raw$state_name[laws_raw$state == abb]
      sname <- if (length(sname) > 0 && !is.na(sname[1])) sname[1] else abb
      row <- df[df$state == abb, ]
      if (nrow(row) == 0) {
        return(paste0("<b>", sname, "</b><br>",
                      "<span style='color:#999;'>No coverage found</span><br>",
                      "<span style='color:#aaa;font-size:0.75em;font-style:italic;'>",
                      "Click for full state details</span>"))
      }
      row$popup_html[[1]]
    }, character(1), USE.NAMES = FALSE)
  })

  # ── Map fill logic ───────────────────────────────────────────────────────────
  # Priority: hover (transient) > group selection (persistent) > neutral gray

  map_fills <- reactive({
    if (input$mode == "condition") {
      hs  <- hover_states()
      sg  <- selected_group()
      si  <- selected_int_states()
      if (!is.null(hs)) {
        # Int bar hover: blue highlight
        vapply(poly_base_names, function(abb) {
          if (abb %in% hs) "#2171b5" else "#e0e0e0"
        }, character(1), USE.NAMES = FALSE)
      } else if (!is.null(sg) || !is.null(si)) {
        # Any persistent selection: red highlight
        sel <- c(sg, si)
        vapply(poly_base_names, function(abb) {
          if (abb %in% sel) "#c0392b" else "#e0e0e0"
        }, character(1), USE.NAMES = FALSE)
      } else {
        rep("#d4d4d4", length(poly_base_names))
      }
    } else {
      # Condition UpSet mode: binary highlight same as Occupation mode
      hs  <- hover_states()
      sg  <- selected_group()
      si  <- selected_int_states()
      if (!is.null(hs)) {
        vapply(poly_base_names, function(abb) {
          if (abb %in% hs) "#2171b5" else "#e0e0e0"
        }, character(1), USE.NAMES = FALSE)
      } else if (!is.null(sg) || !is.null(si)) {
        sel <- c(sg, si)
        vapply(poly_base_names, function(abb) {
          if (abb %in% sel) "#c0392b" else "#e0e0e0"
        }, character(1), USE.NAMES = FALSE)
      } else {
        rep("#d4d4d4", length(poly_base_names))
      }
    }
  })

  # ── Map ──────────────────────────────────────────────────────────────────────

  draw_polygons <- function(proxy_or_leaf, fills, popups) {
    proxy_or_leaf |>
      addPolygons(
        fillColor    = fills,
        fillOpacity  = 0.88,
        color        = "white",
        weight       = 0.9,
        layerId      = states_poly$names,
        popup        = popups,
        label        = lapply(popups, HTML),
        labelOptions = labelOptions(
          style = list("font-family" = "sans-serif", "font-size" = "13px"),
          direction = "auto"
        ),
        highlightOptions = highlightOptions(
          weight = 2.5, color = "#333", fillOpacity = 0.97, bringToFront = TRUE
        )
      )
  }

  output$map <- renderLeaflet({
    lf <- leaflet(data = states_poly,
                  options = leafletOptions(zoomControl = FALSE, attributionControl = FALSE)) |>
      setView(lng = -97, lat = 37, zoom = 4)
    draw_polygons(lf, map_fills(), poly_popups())
  })

  # Re-draw polygons whenever map_fills() changes
  observe({
    leafletProxy("map", data = states_poly) |>
      clearShapes() |>
      draw_polygons(map_fills(), poly_popups())
  })

  # Map click → state details tab
  observeEvent(input$map_shape_click, {
    click <- input$map_shape_click
    if (!is.null(click) && !is.null(click$id)) {
      abb <- gsub(":.*", "", click$id)
      if (abb %in% laws_raw$state) {
        selected_state(abb)
        updateTabsetPanel(session, "main_tabs", selected = "State Details")
      }
    }
  })

  # ── UpSet: bar hover → highlight states + dot column ─────────────────────────

  observeEvent(event_data("plotly_hover", source = "upset_plot"), {
    # Lock out all hover effects while a persistent selection is active
    if (!is.null(selected_grp_idx()) || !is.null(selected_int_idx())) return()

    ed <- event_data("plotly_hover", source = "upset_plot")
    if (!is.null(ed) && !is.null(ed$curveNumber)) {
      cn <- ed$curveNumber[[1]]
      if (cn == 4L) {
        # Intersection bar hover → highlight column + states
        cd  <- ed$customdata[[1]]
        idx <- ed$pointNumber[[1]] + 1L
        if (!is.null(cd) && nchar(cd) > 0) {
          hover_states(strsplit(cd, ",")[[1]])
          hover_int_idx(idx)
          hover_grp_idx(NULL)
          return()
        }
      } else if (cn == 5L) {
        # Set-size bar hover → dim other bars + blue strip + highlight states on map
        grp_idx <- ed$pointNumber[[1]] + 1L
        hover_grp_idx(grp_idx)
        hover_int_idx(NULL)
        covered <- if (input$mode == "condition") {
          # Occupation UpSet: rows = GROUPS (occupations)
          grp <- GROUPS[grp_idx]
          if (input$condition == "all") {
            laws_raw |> filter(responder_type == grp, presumption_exists == TRUE) |>
              pull(state) |> unique()
          } else {
            laws_raw |>
              filter(condition_category == input$condition,
                     responder_type == grp, presumption_exists == TRUE) |>
              pull(state) |> unique()
          }
        } else {
          # Condition UpSet: rows = COND_GROUPS (conditions)
          grp <- COND_GROUPS[grp_idx]
          if (input$responder_type == "all") {
            laws_raw |> filter(condition_category == grp, presumption_exists == TRUE) |>
              pull(state) |> unique()
          } else {
            laws_raw |>
              filter(responder_type == input$responder_type,
                     condition_category == grp, presumption_exists == TRUE) |>
              pull(state) |> unique()
          }
        }
        hover_states(covered)
        return()
      }
    }
    hover_states(NULL)
    hover_int_idx(NULL)
    hover_grp_idx(NULL)
  })

  observeEvent(event_data("plotly_unhover", source = "upset_plot"), {
    # Don't disturb anything while a selection is locked in
    if (!is.null(selected_grp_idx()) || !is.null(selected_int_idx())) return()
    hover_states(NULL)
    hover_int_idx(NULL)
    hover_grp_idx(NULL)
  })

  # ── UpSet: dot + line + strip updates via plotlyProxy ────────────────────────
  # Architecture:
  #   trace 3 = filled dots  → restyle marker.color / size
  #   trace 0 = bg_lines     → restyle line.color (whole trace)
  #   trace 1 = hl_line      → restyle x/y (single hot column; empty otherwise)
  #   layout shapes          → 5 permanent strips; selected row turns blue

  observe({
    col_idx    <- hover_int_idx()
    row_idx    <- selected_grp_idx()
    sint_idx   <- selected_int_idx()
    ud         <- upset_data_r()
    groups     <- active_groups_r()
    if (is.null(ud)) return()

    int_df  <- ud$int_df
    line_df <- upset_lines(int_df, groups)
    filled  <- upset_dot_filled(int_df, groups)
    n_f     <- nrow(filled)
    n_grp   <- length(groups)
    n_int   <- nrow(int_df)
    if (n_f == 0) return()

    col_active  <- !is.null(col_idx)    # hovering an int bar
    row_active  <- !is.null(row_idx)    # set-size bar selected
    sint_active <- !is.null(sint_idx)   # int bar selected

    # ── Filled dot colours / sizes ────────────────────────────────────────────
    # Priority: persistent selection (sint/row) > transient hover (col)
    if (sint_active) {
      in_sel  <- filled$x == sint_idx
      dot_hl  <- "#c0392b"
    } else if (row_active) {
      in_sel  <- filled$y == row_idx
      dot_hl  <- "#c0392b"
    } else if (col_active) {
      in_sel  <- filled$x == col_idx
      dot_hl  <- "#2171b5"
    } else {
      in_sel  <- rep(TRUE, n_f)
      dot_hl  <- "#2171b5"
    }
    colors  <- ifelse(in_sel, dot_hl, "#d0d0d0")
    sizes   <- ifelse(in_sel, 17L, 11L)
    if (!col_active && !row_active && !sint_active) sizes <- rep(16L, n_f)

    plotlyProxy("upset_plot", session) |>
      plotlyProxyInvoke("restyle",
        list("marker.color"      = list(colors),
             "marker.size"       = list(sizes),
             "marker.line.color" = "white",
             "marker.line.width" = 3),
        list(3)   # 0-indexed: trace 3 = filled dots
      )

    # ── Background line trace colour ──────────────────────────────────────────
    bg_color <- if (col_active || row_active || sint_active) "#d0d0d0" else "#2171b5"
    plotlyProxy("upset_plot", session) |>
      plotlyProxyInvoke("restyle",
        list("line.color" = bg_color, "line.width" = 3),
        list(0)   # trace 0 = bg_lines
      )

    # ── Highlighted line trace (column hover OR int bar selection) ────────────
    # When sint_active: show selected column line in red
    # When col_active only: show hovered column line in blue
    hot_col   <- if (sint_active) sint_idx else if (col_active) col_idx else NULL
    hot_color <- if (sint_active) "#c0392b" else "#2171b5"
    if (!is.null(hot_col) && nrow(line_df) > 0) {
      hot_df <- line_df[line_df$x == hot_col, , drop = FALSE]
      if (nrow(hot_df) > 0) {
        hot_x <- c(hot_df$x, hot_df$x, NA_real_)
        hot_y <- c(hot_df$y0, hot_df$y1, NA_real_)
      } else {
        hot_x <- NA_real_; hot_y <- NA_real_
      }
    } else {
      hot_x <- NA_real_; hot_y <- NA_real_
    }
    plotlyProxy("upset_plot", session) |>
      plotlyProxyInvoke("restyle",
        list("x" = list(hot_x), "y" = list(hot_y), "line.color" = hot_color),
        list(1)   # trace 1 = hl_line
      )

    # ── Row strips: selected = warm red, hovered = blue, others = alternating ──
    alt_fill <- c("#f4f4f4", "white", "#f4f4f4", "white", "#f4f4f4")
    sel_fill <- "#fde8e6"   # warm red tint for selection
    hov_fill <- "#dbeeff"   # blue tint for hover
    hgi      <- hover_grp_idx()
    strips <- lapply(seq_len(n_grp), function(i) {
      fc <- if (row_active && i == row_idx) sel_fill
            else if (!is.null(hgi) && i == hgi) hov_fill
            else alt_fill[i]
      list(type      = "rect",
           x0        = 0.22, x1 = 1.0,
           y0        = i - 0.5, y1 = i + 0.5,
           xref      = "paper", yref = "y",
           fillcolor = fc,
           layer     = "below",
           opacity   = 1,
           line      = list(width = 0))
    })
    plotlyProxy("upset_plot", session) |>
      plotlyProxyInvoke("relayout", list(shapes = strips))

    # ── Set-size bar colours (trace 5) ───────────────────────────────────────
    # Priority: persistent selection (red) > transient hover (gray others) > neutral
    # hgi already fetched above for strip colours
    sg_idx <- selected_grp_idx()
    set_bar_colors <- if (!is.null(sg_idx)) {
      cols <- rep("#b0b0b0", n_grp)
      cols[sg_idx] <- "#c0392b"
      cols
    } else if (!is.null(hgi)) {
      cols <- rep("#b0b0b0", n_grp)
      cols[hgi] <- "#2171b5"
      cols
    } else {
      rep("#9ecae1", n_grp)
    }
    plotlyProxy("upset_plot", session) |>
      plotlyProxyInvoke("restyle",
        list("marker.color" = list(set_bar_colors)),
        list(5)   # 0-indexed: trace 5 = set-size bars
      )

    # ── Intersection bar colours (trace 4) ───────────────────────────────────
    # Priority: persistent selection (red) > transient hover (gray others) > neutral
    int_bar_colors <- if (!is.null(sint_idx)) {
      cols <- rep("#b0b0b0", n_int)
      cols[sint_idx] <- "#c0392b"
      cols
    } else if (col_active) {
      cols <- rep("#b0b0b0", n_int)
      cols[col_idx] <- "#2171b5"
      cols
    } else {
      rep("#4292c6", n_int)
    }
    plotlyProxy("upset_plot", session) |>
      plotlyProxyInvoke("restyle",
        list("marker.color" = list(int_bar_colors)),
        list(4)   # 0-indexed: trace 4 = intersection bars
      )
  })

  # ── UpSet: bar click → persistent selection (set-size or intersection) ───────
  # priority = "event" ensures the handler fires even when clicking the same
  # bar twice (Shiny's default "input" priority skips re-fires on identical values)

  observeEvent(event_data("plotly_click", source = "upset_plot", priority = "event"), {
    ed <- event_data("plotly_click", source = "upset_plot", priority = "event")
    if (is.null(ed) || is.null(ed$curveNumber)) return()
    cn <- ed$curveNumber[[1]]

    # ── Trace 5: set-size bar (horizontal, left) ─────────────────────────────
    if (cn == 5L) {
      grp_idx <- ed$pointNumber[[1]] + 1L
      ag      <- active_groups_r()
      if (grp_idx < 1L || grp_idx > length(ag)) return()

      covered <- if (input$mode == "condition") {
        # Occupation UpSet: rows = GROUPS (occupations)
        grp <- GROUPS[grp_idx]
        if (input$condition == "all") {
          laws_raw |> filter(responder_type == grp, presumption_exists == TRUE) |>
            pull(state) |> unique()
        } else {
          laws_raw |>
            filter(condition_category == input$condition,
                   responder_type == grp, presumption_exists == TRUE) |>
            pull(state) |> unique()
        }
      } else {
        # Condition UpSet: rows = COND_GROUPS (conditions)
        grp <- COND_GROUPS[grp_idx]
        if (input$responder_type == "all") {
          laws_raw |> filter(condition_category == grp, presumption_exists == TRUE) |>
            pull(state) |> unique()
        } else {
          laws_raw |>
            filter(responder_type == input$responder_type,
                   condition_category == grp, presumption_exists == TRUE) |>
            pull(state) |> unique()
        }
      }

      # Toggle: same bar → deselect; new bar → select (clears int selection)
      if (!is.null(selected_grp_idx()) && selected_grp_idx() == grp_idx) {
        selected_group(NULL)
        selected_grp_idx(NULL)
      } else {
        selected_group(covered)
        selected_grp_idx(grp_idx)
        selected_int_idx(NULL)       # mutual exclusivity
        selected_int_states(NULL)
      }
      # Flush hover state so map updates immediately on click
      hover_states(NULL); hover_int_idx(NULL); hover_grp_idx(NULL)

    # ── Trace 4: intersection bar (vertical, top) ─────────────────────────────
    } else if (cn == 4L) {
      ud <- upset_data_r()
      if (is.null(ud)) return()
      int_idx <- ed$pointNumber[[1]] + 1L
      if (int_idx < 1L || int_idx > nrow(ud$int_df)) return()

      cd <- ed$customdata[[1]]
      int_states <- if (!is.null(cd) && nchar(cd) > 0)
        strsplit(cd, ",")[[1]] else character(0)

      # Toggle: same bar → deselect; new bar → select (clears group selection)
      if (!is.null(selected_int_idx()) && selected_int_idx() == int_idx) {
        selected_int_idx(NULL)
        selected_int_states(NULL)
      } else {
        selected_int_idx(int_idx)
        selected_int_states(int_states)
        selected_group(NULL)         # mutual exclusivity
        selected_grp_idx(NULL)
      }
      # Flush hover state so map updates immediately on click
      hover_states(NULL); hover_int_idx(NULL); hover_grp_idx(NULL)
    }
    # All visual updates handled by the central observe block
  })

  # ── UpSet plot output ─────────────────────────────────────────────────────────

  output$upset_plot <- renderPlotly({
    make_upset_plot(upset_data_r(), active_groups_r(), active_labels_r(),
                    source_id = "upset_plot")
  })

  output$legend <- renderUI({ legend_occupation_html })

  # ── Stat cards ────────────────────────────────────────────────────────────────

  output$stat_cards <- renderUI({
    mk <- function(col, n, lbl) {
      tags$div(
        style = sprintf(
          "flex:1;min-width:110px;padding:12px 14px;background:%s22;border-left:4px solid %s;border-radius:4px;",
          col, col
        ),
        tags$div(style = sprintf("font-size:1.9em;font-weight:700;color:%s;", col), n),
        tags$div(style = "font-size:0.82em;color:#555;", lbl)
      )
    }

    if (input$mode == "condition") {
      ud <- upset_data_r()
      if (is.null(ud)) return(NULL)
      ag           <- active_groups_r()
      al           <- active_labels_r()
      int_df       <- ud$int_df
      n_states_any <- sum(int_df$n)
      n_combos     <- nrow(int_df)
      top_combo_n  <- int_df$n[1]
      top_groups   <- paste(al[unlist(int_df[1, ag])], collapse = " + ")

      tagList(
        tags$div(
          style = "display:flex;gap:10px;flex-wrap:wrap;margin:12px 0 4px 0;",
          mk("#2171b5", n_states_any, "states with any coverage"),
          mk("#4292c6", n_combos,     "unique group combos"),
          mk("#9ecae1", top_combo_n,  paste0("states: ", top_groups))
        ),
        tags$p(
          style = "font-size:0.78em;color:#777;margin:6px 0 0 0;",
          paste0("Showing: ", cond_label_r(),
                 " — click any state for full details")
        )
      )

    } else {
      df       <- conds_per_state_occ()
      n_any    <- nrow(df)
      avg_c    <- if (n_any > 0) round(mean(df$n_conditions), 1) else 0
      max_c    <- if (n_any > 0) max(df$n_conditions) else 0
      rt_label <- if (input$responder_type == "all") "All occupations"
                  else names(responder_choices)[responder_choices == input$responder_type]

      tagList(
        tags$div(
          style = "display:flex;gap:12px;flex-wrap:wrap;margin:12px 0 4px 0;",
          mk("#2171b5", n_any, "states with any coverage"),
          mk("#4292c6", avg_c, "avg conditions covered"),
          mk("#9ecae1", max_c, "max conditions (one state)")
        ),
        tags$p(style = "font-size:0.78em;color:#777;margin:6px 0 0 0;",
               paste0("Showing: ", rt_label, " — click any state for full details"))
      )
    }
  })

  # ── Detail table ──────────────────────────────────────────────────────────────

  make_collapsed_table <- function(df) {
    df |>
      filter(presumption_exists == TRUE) |>
      mutate(
        Status     = status_labels[presumption_type],
        resp_label = responder_labels[responder_type],
        cond_label = names(conditions)[match(condition_category, conditions)],
        svc_str    = if_else(!is.na(years_service_required),
                             paste0(years_service_required, " yrs"), ""),
        pt_str     = case_when(
          !is.na(post_termination_months) & !is.na(post_termination_formula) ~
            paste0(post_termination_months, " mo max"),
          !is.na(post_termination_months) ~
            paste0(post_termination_months, " mo"),
          isTRUE(discovery_during_employment_required) ~
            "Must dx during employment",
          TRUE ~ ""
        ),
        tobacco_str  = if_else(isTRUE(tobacco_exclusion), "Yes", ""),
        citation_str = if_else(!is.na(statute_citation), statute_citation, ""),
        needs_verif  = isTRUE(needs_verification),
        notes_str    = case_when(
          needs_verif & !is.na(notes) & nchar(trimws(notes)) > 0 ~
            paste0("* Verify active status. ", notes),
          needs_verif ~ "* Verify active status.",
          !is.na(notes) & nchar(trimws(notes)) > 0 ~ notes,
          TRUE ~ ""
        )
      ) |>
      group_by(state_name, cond_label, Status, svc_str, pt_str,
               tobacco_str, citation_str, notes_str, needs_verif) |>
      summarise(Occupations = paste(sort(unique(resp_label)), collapse = ", "),
                .groups = "drop") |>
      arrange(state_name, cond_label) |>
      left_join(state_url_lu, by = "state_name")
  }

  output$table_header <- renderUI({
    st <- selected_state()
    if (!is.null(st)) {
      sname <- laws_raw$state_name[laws_raw$state == st][1]
      iaff  <- state_url_lu$iaff_url[state_url_lu$state == st][1]
      tagList(tags$div(
        style = "display:flex;align-items:center;gap:14px;margin-bottom:10px;",
        h4(paste0("All coverage — ", sname), style = "margin:0;"),
        tags$a("IAFF source ↗", href = iaff, target = "_blank",
               style = "font-size:0.84em;color:#1d6fa5;"),
        actionButton("clear_state", "Back to full table",
                     class = "btn-sm btn-outline-secondary",
                     style = "font-size:0.82em;margin-left:auto;")
      ))
    } else {
      h4(textOutput("table_title_text"))
    }
  })

  output$table_title_text <- renderText({
    if (input$mode == "condition") {
      paste0(cond_label_r(), " — Coverage by state and occupation")
    } else {
      rt_label <- if (input$responder_type == "all") "All occupations"
                  else names(responder_choices)[responder_choices == input$responder_type]
      paste0(rt_label, " — Conditions covered by state")
    }
  })

  observeEvent(input$clear_state, { selected_state(NULL) })

  output$detail_table <- renderDT({
    st <- selected_state()

    df <- if (!is.null(st)) {
      laws_raw |> filter(state == st)
    } else if (input$mode == "condition") {
      if (input$condition == "all") laws_raw
      else laws_raw |> filter(condition_category == input$condition)
    } else {
      if (input$responder_type == "all") laws_raw
      else laws_raw |> filter(responder_type == input$responder_type)
    }

    tbl <- make_collapsed_table(df)

    if (nrow(tbl) == 0)
      return(datatable(data.frame(Note = "No active coverage found."),
                       rownames = FALSE, options = list(dom = "t")))

    # Embed the IAFF link directly into the citation text
    tbl <- tbl |>
      mutate(
        citation_str = case_when(
          !is.na(iaff_url) & nchar(citation_str) > 0 ~
            paste0('<a href="', iaff_url, '" target="_blank">', citation_str, '</a>'),
          !is.na(iaff_url) ~
            paste0('<a href="', iaff_url,
                   '" target="_blank" style="white-space:nowrap;">IAFF source ↗</a>'),
          TRUE ~ citation_str
        )
      )

    tbl_out <- if (!is.null(st)) {
      tbl |> select(Condition = cond_label, Occupations, Status,
                    `Service req.` = svc_str, `Post-employment` = pt_str,
                    `Tobacco excl.` = tobacco_str, Citation = citation_str,
                    Notes = notes_str)
    } else if (input$mode == "condition") {
      tbl |> select(State = state_name, Condition = cond_label, Occupations, Status,
                    `Service req.` = svc_str, `Post-employment` = pt_str,
                    `Tobacco excl.` = tobacco_str, Citation = citation_str,
                    Notes = notes_str)
    } else {
      tbl |> select(State = state_name, Condition = cond_label, Status,
                    `Service req.` = svc_str, `Post-employment` = pt_str,
                    `Tobacco excl.` = tobacco_str, Citation = citation_str,
                    Notes = notes_str)
    }

    tob_col <- which(names(tbl_out) == "Tobacco excl.") - 1L

    datatable(
      tbl_out,
      escape   = FALSE,
      rownames = FALSE,
      class    = "stripe hover compact",
      options  = list(
        pageLength = 25,
        scrollX    = TRUE,
        dom        = "frtip",
        columnDefs = list(
          list(className = "dt-center", targets = tob_col)
        )
      )
    )
  })
}

shinyApp(ui, server)
