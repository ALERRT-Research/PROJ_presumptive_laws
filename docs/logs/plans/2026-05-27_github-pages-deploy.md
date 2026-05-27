# Plan: GitHub Pages Deployment
**Status:** DRAFT
**Created:** 2026-05-27

## Goal
Host the static Quarto + Shinylive site on GitHub Pages so it's publicly accessible.

## Prerequisites (confirm with Peter at session start)
- [ ] Which GitHub account/org? (Peter has other GH Pages sites — use same account)
- [ ] Repo name? (e.g., `presumptive-laws` → `[account].github.io/presumptive-laws`)
- [ ] Should the repo be public or private? (GH Pages on free plan requires public)
- [ ] Does a repo already exist, or do we create one?

## Approach: GitHub Actions (recommended)

Rather than manually pushing `_site/`, set up a GH Actions workflow that:
1. Triggers on push to `main`
2. Installs R, Quarto, and required packages
3. Runs `shinylive::export()` and `quarto render`
4. Deploys `_site/` to the `gh-pages` branch

**Why this is better than manual push:** future data updates just require committing the source files — the site rebuilds automatically.

## Steps

### Phase 1: Repo setup
1. Create repo on GitHub (or confirm existing)
2. Initialize git in project root (currently not a git repo)
3. Create `.gitignore` to exclude:
   - `data/raw/` (large scraped files, not needed for deployment)
   - `website/_site/` (built artifact — Actions will rebuild)
   - `website/dashboard/` (Shinylive bundle — Actions will rebuild)
   - `data/processed/*.rds` / `*.csv` (derivable from source)
   - `.Rproj.user/`, `.DS_Store`, etc.
4. Initial commit of source files
5. Push to `main`

### Phase 2: GitHub Actions workflow
Create `.github/workflows/deploy.yml`:
- Trigger: `push` to `main`
- Runner: `ubuntu-latest`
- Steps:
  1. Checkout repo
  2. Install R + packages (`pacman`, `shinylive`, `jsonlite`, `dplyr`, etc.)
  3. Install Quarto
  4. Run `shinylive::export('website/shiny-app', 'website/dashboard', overwrite=TRUE)`
  5. Run `quarto render website/`
  6. Deploy `website/_site/` to `gh-pages` branch via `peaceiris/actions-gh-pages`

### Phase 3: GH Pages settings
- In repo Settings → Pages: set source to `gh-pages` branch, root `/`
- Confirm site is live at `[account].github.io/[repo]`

### Phase 4: Post-deploy
- Update `index.qmd` suggested citation with live URL
- Update `about.qmd` if needed
- Test the live site: map loads, Shinylive app runs, both modes work

## Alternative: Manual push (simpler, no Actions)
If Actions setup is too heavy for a prototype:
1. Build locally (`quarto render`)
2. Create orphan `gh-pages` branch
3. Copy `_site/` contents to branch root
4. Push `gh-pages` to remote
5. Repeat manually after each update

**Downside:** every update requires remembering to rebuild and push manually.

## Decision needed from Peter
- Actions vs. manual? (Actions recommended if staying active; manual fine for one-shot prototype)
- Public vs. private repo?
- Repo name / account?
