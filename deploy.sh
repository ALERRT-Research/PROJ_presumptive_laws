#!/bin/bash
# deploy.sh — Build and push site to gh-pages branch
# Usage: bash deploy.sh
# Run from the project root (PROJ_presumptive_laws/).

set -e

REPO_URL="https://github.com/ALERRT-Research/PROJ_presumptive_laws.git"

echo "=== Step 1: Build Shinylive export ==="
cd website
Rscript -e "shinylive::export('shiny-app', 'dashboard', overwrite=TRUE)"

echo ""
echo "=== Step 2: Render Quarto site ==="
quarto render
cd ..

echo ""
echo "=== Step 3: Push _site/ to gh-pages ==="
TMP=$(mktemp -d)
cp -r website/_site/. "$TMP/"
touch "$TMP/.nojekyll"   # tell GitHub Pages not to run Jekyll

cd "$TMP"
git init -q
git checkout -b gh-pages
git add .
git commit -q -m "Deploy: $(date '+%Y-%m-%d %H:%M')"
git push --force "$REPO_URL" gh-pages
cd -
rm -rf "$TMP"

echo ""
echo "Done. Site deployed to gh-pages."
echo "If this is your first deploy, go to:"
echo "  https://github.com/ALERRT-Research/presumptive-laws/settings/pages"
echo "  Source: Deploy from branch → gh-pages → / (root)"
