# PROJ_presumptive_laws

**Created:** 2026-05-21

## Project Description

Interactive web dashboard mapping presumptive workers' compensation laws for first responders across all 50 US states. Covers condition type (cancer, cardiovascular, respiratory, infectious disease, COVID-19, mental health/PTSD), first responder group (firefighter, EMS, police, volunteer), and key law attributes. Built for policymakers and first responder families.

## Data Sources

Data are drawn primarily from the **IAFF Presumptive Health database** ([iaff.org/presumptive-health](https://www.iaff.org/presumptive-health/)), maintained by the International Association of Fire Fighters. The IAFF pages cover all 50 states and are regularly updated with statute citations and condition-level detail.

Two published academic reviews were used for cross-checking during initial development:
- NCCI (2023). *Firefighters and First Responders: 2023 Update on Presumptive Workers Comp Benefits.* (~38 NCCI-jurisdiction states, through Nov 2022)
- Brandt-Rauf, S., Davis, A. L., & Taylor, J. A. (2024). Inventory of state workers' compensation laws in the United States: first responder mental health. *Journal of Public Health Policy*, 45, 562–574. (50-state inventory, through Dec 2022)

## Collaborators

No external collaborators.

## Tech Stack

Quarto website + Shinylive (Shiny in WebAssembly). Fully static — no server required.
