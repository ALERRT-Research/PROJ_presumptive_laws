library(shiny)
library(bslib)
library(dplyr)
library(jsonlite)
library(leaflet)
library(maps)

# ── Static reference data ─────────────────────────────────────────────────────

laws_raw <- fromJSON("data/presumptive_laws.json", simplifyVector = TRUE)
laws_raw$presumption_exists                  <- as.logical(laws_raw$presumption_exists)
laws_raw$rebuttable                          <- as.logical(laws_raw$rebuttable)
laws_raw$tobacco_exclusion                   <- as.logical(laws_raw$tobacco_exclusion)
laws_raw$discovery_during_employment_required <- as.logical(laws_raw$discovery_during_employment_required)
laws_raw$years_service_required              <- suppressWarnings(as.integer(laws_raw$years_service_required))
laws_raw$post_termination_months             <- suppressWarnings(as.integer(laws_raw$post_termination_months))

type_priority <- c(statute = 4L, EO = 3L, expired = 2L, none = 1L)

status_labels <- c(
  statute = "Active statute",
  EO      = "Executive order",
  expired = "Expired / lapsed",
  none    = "No law found"
)

clrs <- c(
  statute = "#1d6fa5",
  EO      = "#e07b00",
  expired = "#b0b0b0",
  none    = "#e8e8e8"
)

conditions <- c(
  "Cancer"                 = "cancer",
  "Cardiovascular Disease" = "cardiovascular",
  "Respiratory Disease"    = "respiratory",
  "Infectious Disease"     = "infectious",
  "Mental Health / PTSD"   = "mental",
  "Other"                  = "other"
)

responder_choices <- c(
  "Any covered group"       = "any",
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

# State name → abbreviation lookup (built-in R datasets + DC)
state_lu <- data.frame(
  name_lower = c(tolower(state.name), "district of columbia"),
  abb        = c(state.abb, "DC"),
  stringsAsFactors = FALSE
)

# US state polygons — load once at startup
states_poly     <- map("state", fill = TRUE, plot = FALSE)
poly_base_names <- gsub(":.*", "", states_poly$names)

# ── Legend HTML ───────────────────────────────────────────────────────────────

legend_html <- HTML(paste0(
  '<div style="font-size:0.82em;line-height:2.1;">',
  '<span style="display:inline-block;width:13px;height:13px;background:#1d6fa5;',
    'border-radius:2px;margin-right:6px;vertical-align:middle;"></span>Active statute<br>',
  '<span style="display:inline-block;width:13px;height:13px;background:#e07b00;',
    'border-radius:2px;margin-right:6px;vertical-align:middle;"></span>Executive order<br>',
  '<span style="display:inline-block;width:13px;height:13px;background:#b0b0b0;',
    'border-radius:2px;margin-right:6px;vertical-align:middle;"></span>Expired / lapsed<br>',
  '<span style="display:inline-block;width:13px;height:13px;background:#e8e8e8;',
    'border:1px solid #bbb;border-radius:2px;margin-right:6px;vertical-align:middle;">',
    '</span>No law found',
  '</div>'
))

# ── UI ────────────────────────────────────────────────────────────────────────

ui <- fluidPage(
  theme = bs_theme(bootswatch = "cosmo"),
  titlePanel("First Responder Presumptive Laws"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("condition", "Condition",
                  choices  = conditions,
                  selected = "cancer"),
      selectInput("responder_type", "Responder type",
                  choices  = responder_choices,
                  selected = "any"),
      hr(),
      tags$p(tags$strong("Map key"), style = "margin-bottom:4px; font-size:0.88em;"),
      legend_html,
      hr(),
      tags$p(
        "Data sourced from the",
        tags$a("IAFF Presumptive Health Initiative",
               href   = "https://www.iaff.org/presumptive-health/",
               target = "_blank"),
        ". Always verify with a qualified attorney or your state's workers' compensation board.",
        style = "font-size:0.78em; color:#777; margin-top:4px;"
      )
    ),
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel(
          "Map",
          br(),
          leafletOutput("map", height = "560px"),
          br(),
          uiOutput("stat_cards")
        ),
        tabPanel(
          "State Details",
          br(),
          h4(textOutput("table_title")),
          tableOutput("detail_table")
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # All rows for selected condition × responder type
  cond_data <- reactive({
    df <- laws_raw |> filter(condition_category == input$condition)
    if (input$responder_type != "any") {
      df <- df |> filter(responder_type == input$responder_type)
    }
    df
  })

  # One row per state: best coverage for map coloring and stat cards
  best_per_state <- reactive({
    cond_data() |>
      mutate(priority = type_priority[presumption_type]) |>
      group_by(state, state_name) |>
      slice_max(priority, n = 1, with_ties = FALSE) |>
      ungroup()
  })

  # Covered groups per state — for popup aggregation when "any" is selected
  groups_per_state <- reactive({
    cond_data() |>
      filter(presumption_exists == TRUE) |>
      mutate(group_label = responder_labels[responder_type]) |>
      group_by(state) |>
      summarise(
        covered_groups   = paste(sort(unique(group_label)), collapse = ", "),
        min_svc_yrs      = suppressWarnings(min(years_service_required, na.rm = TRUE)),
        max_post_term_mo = suppressWarnings(max(post_termination_months, na.rm = TRUE)),
        .groups = "drop"
      ) |>
      mutate(
        min_svc_yrs      = ifelse(is.infinite(min_svc_yrs),      NA_real_, min_svc_yrs),
        max_post_term_mo = ifelse(is.infinite(max_post_term_mo), NA_real_, max_post_term_mo)
      )
  })

  # Full display data for map popups
  map_data <- reactive({
    best <- best_per_state()
    grps <- groups_per_state()

    best |>
      left_join(grps, by = "state") |>
      mutate(
        fill_color   = clrs[presumption_type],
        status_label = status_labels[presumption_type],

        # Pick the right service and post-termination values for display
        svc_yr = coalesce(years_service_required, min_svc_yrs),
        pt_mo  = coalesce(post_termination_months, max_post_term_mo),

        svc_str = if_else(!is.na(svc_yr),
          paste0(as.integer(svc_yr), " yr min service"), NA_character_),
        pt_str  = if_else(!is.na(pt_mo),
          paste0(as.integer(pt_mo), " mo post-employment coverage"), NA_character_),

        popup_html = paste0(
          "<b style='font-size:1.05em;'>", state_name, "</b><br>",
          "<span style='color:", fill_color, ";font-weight:600;'>",
            status_label, "</span>",
          if_else(!is.na(covered_groups),
            paste0("<br><span style='color:#444;font-size:0.88em;'>",
                   covered_groups, "</span>"),
            ""),
          if_else(!is.na(statute_citation),
            paste0("<br><span style='color:#777;font-size:0.82em;'>",
                   statute_citation, "</span>"),
            ""),
          if_else(!is.na(svc_str),
            paste0("<br><span style='color:#888;font-size:0.80em;'>",
                   svc_str, "</span>"),
            ""),
          if_else(!is.na(pt_str),
            paste0("<br><span style='color:#888;font-size:0.80em;'>",
                   pt_str, "</span>"),
            "")
        )
      )
  })

  # Polygon fill colors keyed to state
  poly_fills <- reactive({
    df <- map_data()
    vapply(poly_base_names, function(nm) {
      abb <- state_lu$abb[state_lu$name_lower == nm]
      if (length(abb) == 0) return(clrs["none"])
      row <- df[df$state == abb, ]
      if (nrow(row) == 0) return(clrs["none"])
      row$fill_color[[1]]
    }, character(1), USE.NAMES = FALSE)
  })

  # Polygon popup HTML keyed to state
  poly_popups <- reactive({
    df <- map_data()
    vapply(poly_base_names, function(nm) {
      abb <- state_lu$abb[state_lu$name_lower == nm]
      if (length(abb) == 0) return(nm)
      row <- df[df$state == abb, ]
      if (nrow(row) == 0) return(nm)
      row$popup_html[[1]]
    }, character(1), USE.NAMES = FALSE)
  })

  output$map <- renderLeaflet({
    leaflet(
      data    = states_poly,
      options = leafletOptions(zoomControl = FALSE, attributionControl = FALSE)
    ) |>
      addProviderTiles("CartoDB.PositronNoLabels") |>
      addPolygons(
        fillColor    = poly_fills(),
        fillOpacity  = 0.82,
        color        = "white",
        weight       = 1.2,
        popup        = poly_popups(),
        label        = lapply(poly_popups(), HTML),
        labelOptions = labelOptions(
          style     = list("font-family" = "sans-serif", "font-size" = "13px"),
          direction = "auto"
        ),
        highlightOptions = highlightOptions(
          weight       = 2.5,
          color        = "#444",
          fillOpacity  = 0.95,
          bringToFront = TRUE
        )
      ) |>
      setView(lng = -98, lat = 39, zoom = 4)
  })

  output$stat_cards <- renderUI({
    df   <- best_per_state()
    n_st <- sum(df$presumption_type == "statute", na.rm = TRUE)
    n_eo <- sum(df$presumption_type == "EO",      na.rm = TRUE)
    n_no <- sum(df$presumption_type %in% c("none", "expired"), na.rm = TRUE)

    note <- if (input$responder_type != "any") {
      rt_label <- names(responder_choices)[responder_choices == input$responder_type]
      tags$p(
        style = "font-size:0.78em;color:#777;margin:6px 0 0 0;",
        paste0("Showing coverage for: ", rt_label)
      )
    } else {
      tags$p(
        style = "font-size:0.78em;color:#777;margin:6px 0 0 0;",
        "Map shows best available coverage across all responder types."
      )
    }

    mk <- function(col, n, lbl) {
      tags$div(
        style = sprintf(
          "flex:1;min-width:110px;padding:12px 14px;background:%s18;border-left:4px solid %s;border-radius:4px;",
          col, col
        ),
        tags$div(style = sprintf("font-size:1.9em;font-weight:700;color:%s;", col), n),
        tags$div(style = "font-size:0.82em;color:#555;", lbl)
      )
    }

    tagList(
      tags$div(
        style = "display:flex;gap:12px;flex-wrap:wrap;margin:12px 0 4px 0;",
        mk(clrs["statute"], n_st, "active statutes"),
        mk(clrs["EO"],      n_eo, "executive orders"),
        mk("#999",          n_no, "no law found")
      ),
      note
    )
  })

  output$table_title <- renderText({
    cond_label <- names(conditions)[conditions == input$condition]
    rt         <- input$responder_type
    if (rt == "any") {
      paste0(cond_label, " Protections — All Responder Types")
    } else {
      rt_label <- names(responder_choices)[responder_choices == rt]
      paste0(cond_label, " Protections — ", rt_label)
    }
  })

  output$detail_table <- renderTable({
    cond_data() |>
      filter(presumption_exists == TRUE) |>
      mutate(
        Status           = status_labels[presumption_type],
        `Responder type` = responder_labels[responder_type],
        `Service req.`   = if_else(
          !is.na(years_service_required),
          paste0(years_service_required, " yrs"), ""
        ),
        `Post-employment` = case_when(
          !is.na(post_termination_months) & !is.na(post_termination_formula) ~
            paste0(post_termination_months, " mo max"),
          !is.na(post_termination_months) ~
            paste0(post_termination_months, " mo"),
          isTRUE(discovery_during_employment_required) ~
            "Must dx during employment",
          TRUE ~ ""
        ),
        `Tobacco exclusion` = if_else(isTRUE(tobacco_exclusion), "Yes", ""),
        Citation            = if_else(!is.na(statute_citation), statute_citation, ""),
        Notes               = if_else(
          !is.na(notes) & nchar(trimws(notes)) > 0, notes, ""
        )
      ) |>
      select(
        State            = state_name,
        Status,
        `Responder type`,
        `Service req.`,
        `Post-employment`,
        `Tobacco exclusion`,
        Citation,
        Notes
      ) |>
      arrange(State, `Responder type`)
  }, striped = TRUE, hover = TRUE, bordered = FALSE, na = "")
}

shinyApp(ui, server)
