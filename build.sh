#!/bin/bash
# Rebuilds the five games from their own repositories and copies each one into this site.
#
#   ./build.sh                 # every game
#   ./build.sh amped-ascent    # only the ones named
#
# The game repositories are looked for next to this one (../superdaddio, ../blorps-big-romp,
# ../blorps-big-romp2, ../AmpedAscent). Set GAMES_DIR to look somewhere else. A repository that is
# not there is cloned from GitHub into .sources/, which git ignores.
#
# Needs bash, git and Node.js 22 or newer.
set -euo pipefail
cd "$(dirname "$0")"
SITE=$PWD
GAMES_DIR=${GAMES_DIR:-$SITE/..}
OWNER=https://github.com/glennbacon

# Prints the path of a game's repository, cloning it first if there is no copy on this machine.
source_of() {
  local repo=$1
  if [ -d "$GAMES_DIR/$repo" ]; then
    (cd "$GAMES_DIR/$repo" && pwd)
  else
    [ -d "$SITE/.sources/$repo" ] || git clone --depth 1 "$OWNER/$repo" "$SITE/.sources/$repo" >&2
    echo "$SITE/.sources/$repo"
  fi
}

# Replaces a game's folder in the site with a freshly built one.
publish() {
  local slug=$1 built=$2
  rm -rf "${SITE:?}/$slug"
  mkdir -p "$SITE/$slug"
  cp -R "$built/." "$SITE/$slug/"
  echo "  $slug: $(find "$SITE/$slug" -type f | wc -l | tr -d ' ') files, $(du -sh "$SITE/$slug" | cut -f1)"
}

# A Vite project: install what it needs, build it, publish dist/.
vite_game() {
  local slug=$1 dir=$2
  echo "building $slug"
  (cd "$dir" && npm ci --no-audit --no-fund --silent && npm run build --silent) >&2
  publish "$slug" "$dir/dist"
}

# A game that is one built page, kept in its repository as index.html.
page_game() {
  local slug=$1 dir=$2
  echo "copying $slug"
  local tmp
  tmp=$(mktemp -d)
  cp "$dir/index.html" "$tmp/"
  publish "$slug" "$tmp"
  rm -rf "$tmp"
}

build() {
  case $1 in
    super-daddio)       vite_game "$1" "$(source_of superdaddio)/web" ;;
    super-daddio-voxel) vite_game "$1" "$(source_of superdaddio)/voxel" ;;
    blorps-big-romp)    page_game "$1" "$(source_of blorps-big-romp)" ;;
    blorps-big-romp-2)  page_game "$1" "$(source_of blorps-big-romp2)" ;;
    amped-ascent)       vite_game "$1" "$(source_of AmpedAscent)" ;;
    *) echo "unknown game: $1" >&2; exit 1 ;;
  esac
}

if [ $# -eq 0 ]; then
  set -- super-daddio super-daddio-voxel blorps-big-romp blorps-big-romp-2 amped-ascent
fi
for game in "$@"; do build "$game"; done
echo "done"
