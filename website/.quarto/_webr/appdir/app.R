library(shiny)
library(bslib)
library(dplyr)
library(plotly)
library(jsonlite)

# ── Static reference data ─────────────────────────────────────────────────────

# Data is served as a static file from the website's data/ directory.
# fromJSON() makes an HTTP fetch in the webR/WASM environment.
laws_raw <- fromJSON("data/presumptive_laws.json", simplifyVector = TRUE)
laws_raw$presumption_exists <- as.logical(laws_raw$presumption_exists)

# Priority order when a state appears in both Brandt-Rauf (none) and IAFF (statute)
type_priority <- c(statute = 4L, EO = 3L, expired = 2L, none = 1L)

status_labels <- c(
  statute = "Active statute",
  EO      = "Executive order",
  expired = "Expired / lapsed",
  none    = "No law found"
)

# z-values for discrete choropleth (1 = none … 4 = statute)
type_z <- c(none = 1L, expired = 2L, EO = 3L, statute = 4L)

clrs <- c(
  statute = "#1d6fa5",
  EO      = "#e07b00",
  expired = "#b0b0b0",
  none    = "#e8e8e8"
)

# Stepped colorscale: narrow transition zones between levels so no z-value
# falls inside a blended region (z-values 1–4 with zmin=0.5, zmax=4.5).
discrete_scale <- list(
  list(0,    clrs["none"]),    list(0.24, clrs["none"]),
  list(0.26, clrs["expired"]), list(0.49, clrs["expired"]),
  list(0.51, clrs["EO"]),      list(0.74, clrs["EO"]),
  list(0.76, clrs["statute"]), list(1.0,  clrs["statute"])
)

conditions <- c(
  "Cancer"                 = "cancer",
  "Cardiovascular Disease" = "cardiovascular",
  "Respiratory Disease"    = "respiratory",
  "Infectious Disease"     = "infectious",
  "COVID-19"               = "covid19",
  "Mental Health / PTSD"   = "mental"
)

legend_html <- function() {
  make_swatch <- function(col, border = FALSE) {
    border_style <- if (border) "border:1px solid #bbb;" else ""
    sprintf(
      '<span style="display:inline-block;width:13px;height:13px;background:%s;%sborder-radius:2px;margin-right:6px;vertical-align:middle;"></span>',
      col, border_style
    )
  }
  HTML(paste0(
    '<div style="font-size:0.82em;line-height:2.1;">',
    make_swatch(clrs["statute"]),  "Active statute<br>",
    make_swatch(clrs["EO"]),       "Executive order<br>",
    make_swatch(clrs["expired"]),  "Expired / lapsed<br>",
    make_swatch(clrs["none"], border = TRUE), "No law found",
    "</div>"
  ))
}

# ── UI ────────────────────────────────────────────────────────────────────────

ui <- page_sidebar(
  title = "First Responder Presumptive Laws",
  theme = bs_theme(bootswatch = "cosmo"),
  sidebar = sidebar(
    width = 230,
    selectInput("condition", "Condition",
                choices  = conditions,
                selected = "cancer"),
    hr(),
    tags$p(tags$strong("Map key"), style = "margin-bottom:4px; font-size:0.88em;"),
    legend_html(),
    hr(),
    tags$p(
      "Data current through December 2022.",
      tags$br(),
      "Always verify with an attorney.",
      style = "font-size:0.78em; color:#777; margin-top:4px;"
    )
  ),
  plotlyOutput("map", height = "460px"),
  uiOutput("stat_cards"),
  card(
    card_header(textOutput("table_title")),
    tableOutput("detail_table"),
    style = "margin-top:10px;"
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # One row per state: take highest-priority status when IAFF and Brandt-Rauf
  # both have a row for the same state × condition.
  filtered <- reactive({
    laws_raw |>
      filter(condition == input$condition) |>
      mutate(priority = type_priority[presumption_type]) |>
      group_by(state) |>
      slice_max(priority, n = 1, with_ties = FALSE) |>
      ungroup() |>
      mutate(
        z_val  = type_z[presumption_type],
        groups_fmt   = if_else(
          !is.na(ncci_groups),
          gsub(";", ", ", ncci_groups),
          "Data not available"
        ),
        citation_fmt = if_else(!is.na(statute_citation), statute_citation, "—"),
        hover = paste0(
          "<b>", state_name, "</b><br>",
          status_labels[presumption_type],
          if_else(
            !is.na(ncci_groups),
            paste0("<br>Groups: ", groups_fmt),
            ""
          ),
          if_else(
            !is.na(statute_citation),
            paste0("<br>", statute_citation),
            ""
          ),
          if_else(
            !is.na(notes) & nchar(trimws(notes)) > 0,
            paste0("<br><i>", notes, "</i>"),
            ""
          )
        )
      )
  })

  output$map <- renderPlotly({
    df <- filtered()

    plot_ly(
      data         = df,
      type         = "choropleth",
      locations    = ~state,
      locationmode = "USA-states",
      z            = ~z_val,
      text         = ~hover,
      hoverinfo    = "text",
      colorscale   = discrete_scale,
      zmin         = 0.5,
      zmax         = 4.5,
      showscale    = FALSE,
      marker       = list(line = list(color = "white", width = 1.2))
    ) |>
      layout(
        geo = list(
          scope     = "usa",
          showlakes = FALSE,
          bgcolor   = "rgba(0,0,0,0)"
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)",
        margin        = list(l = 0, r = 0, t = 8, b = 0)
      ) |>
      config(displayModeBar = FALSE)
  })

  output$stat_cards <- renderUI({
    df    <- filtered()
    n_st  <- sum(df$presumption_type == "statute",            na.rm = TRUE)
    n_eo  <- sum(df$presumption_type == "EO",                 na.rm = TRUE)
    n_no  <- sum(df$presumption_type %in% c("none","expired"), na.rm = TRUE)

    card_style <- function(col) {
      sprintf(
        "flex:1;min-width:110px;padding:12px 14px;background:%s18;border-left:4px solid %s;border-radius:4px;",
        col, col
      )
    }
    num_style  <- function(col) sprintf("font-size:1.9em;font-weight:700;color:%s;", col)
    lbl_style  <- "font-size:0.82em;color:#555;"

    tags$div(
      style = "display:flex;gap:12px;flex-wrap:wrap;margin:12px 0 4px 0;",
      tags$div(style = card_style(clrs["statute"]),
               tags$div(style = num_style(clrs["statute"]), n_st),
               tags$div(style = lbl_style, "active statutes")),
      tags$div(style = card_style(clrs["EO"]),
               tags$div(style = num_style(clrs["EO"]), n_eo),
               tags$div(style = lbl_style, "executive orders")),
      tags$div(style = card_style("#999"),
               tags$div(style = num_style("#777"), n_no),
               tags$div(style = lbl_style, "no law found"))
    )
  })

  output$table_title <- renderText({
    cond_label <- names(conditions)[conditions == input$condition]
    paste0("States with ", cond_label, " Protections")
  })

  output$detail_table <- renderTable({
    df <- filtered()
    df |>
      filter(presumption_exists) |>
      transmute(
        State    = state_name,
        Status   = status_labels[presumption_type],
        `Covered groups`  = groups_fmt,
        `Statute citation` = citation_fmt,
        Notes    = if_else(!is.na(notes) & nchar(trimws(notes)) > 0, notes, "")
      ) |>
      arrange(State)
  }, striped = TRUE, hover = TRUE, bordered = FALSE, na = "")

}

shinyApp(ui, server)
