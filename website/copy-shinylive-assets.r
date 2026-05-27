# Pre-render: copy Shinylive JS assets to _site.
# Quarto registers the dependency but doesn't copy the shinylive/ subdirectory;
# this script fills that gap so the browser can load the app.

ver  <- shinylive::assets_version()
src  <- file.path(shinylive:::assets_cache_dir(), paste0("shinylive-", ver), "shinylive")
dest <- file.path("_site", "site_libs", "quarto-contrib",
                  paste0("shinylive-", ver), "shinylive")

if (!dir.exists(dest)) dir.create(dest, recursive = TRUE)
file.copy(list.files(src, full.names = TRUE), dest, recursive = TRUE, overwrite = TRUE)
message("Shinylive assets copied: ", ver)
