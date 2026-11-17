#!/bin/bash
# Rebuilds the five games from their own repositories and copies each one into this site.
#
#   ./build.sh                 # every game, from the copies of the repositories on this machine
#   ./build.sh amped-ascent    # only the ones named
#   ./build.sh --latest        # only the games that have changed on GitHub (what the workflow runs)
#   ./build.sh --latest amped-ascent   # the ones named, from GitHub, changed or not
#   ./build.sh --latest all            # every game, from GitHub, changed or not
#
# Without --latest, the game repositories are looked for next to this one (../superdaddio,
# ../blorps-big-romp, ../blorps-big-romp2, ../AmpedAscent), and whatever is checked out there is
# built. Set GAMES_DIR to look somewhere else. A repository that is not there is cloned from GitHub
# into .sources/, which git ignores.
#
# With --latest, the repositories on this machine are left alone. Each game is built from a fresh
# clone of its repository's default branch, and when no games are named, only the games whose
# repository has moved on since their copy here was built. A game that fails to build keeps its old
# copy, the others are still updated, and the script ends with an error.
#
# versions.txt records the commit each copy was built from.
#
# Needs bash, git and Node.js 22 or newer.
set -euo pipefail
cd "$(dirname "$0")"
SITE=$PWD
GAMES_DIR=${GAMES_DIR:-$SITE/..}
OWNER=https://github.com/glennbacon
VERSIONS=$SITE/versions.txt
ALL_GAMES="super-daddio super-daddio-voxel blorps-big-romp blorps-big-romp-2 amped-ascent"

LATEST=
if [ "${1:-}" = "--latest" ]; then LATEST=1; shift; fi

# The repository a game is built from.
repo_of() {
  case $1 in
    super-daddio|super-daddio-voxel) echo superdaddio ;;
    blorps-big-romp)                 echo blorps-big-romp ;;
    blorps-big-romp-2)               echo blorps-big-romp2 ;;
    amped-ascent)                    echo AmpedAscent ;;
    *) echo "unknown game: $1" >&2; return 1 ;;
  esac
}

# Prints the path of a game's repository, cloning it first if there is no copy to use.
source_of() {
  local repo=$1
  if [ -z "$LATEST" ] && [ -d "$GAMES_DIR/$repo" ]; then
    (cd "$GAMES_DIR/$repo" && pwd)
  else
    if [ ! -d "$SITE/.sources/$repo" ]; then
      git clone --quiet --depth 1 "$OWNER/$repo" "$SITE/.sources/$repo" >&2 || return 1
    fi
    echo "$SITE/.sources/$repo"
  fi
}

# The commit a repository is at, marked if it also holds changes that are not committed.
commit_of() {
  local sha
  sha=$(git -C "$1" rev-parse HEAD) || return 1
  [ -z "$(git -C "$1" status --porcelain)" ] || sha="$sha+uncommitted"
  echo "$sha"
}

# The commit at the head of a repository's default branch on GitHub.
latest_of() { git ls-remote "$OWNER/$1" HEAD | cut -f1; }

# The commit a game's copy in this site was built from, or nothing if that was never recorded.
built_from() {
  [ -f "$VERSIONS" ] || return 0
  awk -v game="$1" '$1 == game { print $3 }' "$VERSIONS"
}

# Writes versions.txt again with one game's commit changed.
record() {
  local slug=$1 sha=$2 tmp game old
  tmp=$(mktemp)
  {
    echo "# The commit of each game's repository that its copy in this site was built from."
    echo "# Written by build.sh. Each line is: game, repository, commit."
    for game in $ALL_GAMES; do
      if [ "$game" = "$slug" ]; then
        echo "$game $(repo_of "$game") $sha"
      else
        old=$(built_from "$game")
        [ -z "$old" ] || echo "$game $(repo_of "$game") $old"
      fi
    done
  } > "$tmp"
  cat "$tmp" > "$VERSIONS"
  rm -f "$tmp"
}

# Replaces a game's folder in the site with a freshly built one. The new copy is made complete
# beside the old one first, so a copy that fails part-way leaves the old folder as it was.
publish() {
  local slug=$1 built=$2 fresh="$SITE/.$1.new"
  rm -rf "$fresh"
  mkdir -p "$fresh"
  cp -R "$built/." "$fresh/"
  rm -rf "${SITE:?}/$slug"
  mv "$fresh" "$SITE/$slug"
  echo "  $slug: $(find "$SITE/$slug" -type f | wc -l | tr -d ' ') files, $(du -sh "$SITE/$slug" | cut -f1)"
}

# A Vite project: install what it needs, build it, publish dist/.
vite_game() {
  local slug=$1 dir=$2
  (cd "$dir" && npm ci --no-audit --no-fund --silent && npm run build --silent) >&2
  publish "$slug" "$dir/dist"
}

# A game that is one built page, kept in its repository as index.html.
page_game() {
  local slug=$1 dir=$2 tmp
  tmp=$(mktemp -d)
  cp "$dir/index.html" "$tmp/"
  publish "$slug" "$tmp"
  rm -rf "$tmp"
}

build() {
  local slug=$1 repo root sha
  repo=$(repo_of "$slug")
  root=$(source_of "$repo")
  sha=$(commit_of "$root")
  echo "building $slug from $repo $(echo "$sha" | cut -c1-7)"
  case $slug in
    super-daddio)       vite_game "$slug" "$root/web" ;;
    super-daddio-voxel) vite_game "$slug" "$root/voxel" ;;
    amped-ascent)       vite_game "$slug" "$root" ;;
    *)                  page_game "$slug" "$root" ;;
  esac
  record "$slug" "$sha"
}

# ---------------------------------------------------------------- from this machine
if [ -z "$LATEST" ]; then
  if [ $# -eq 0 ] || [ "$1" = all ]; then set -- $ALL_GAMES; fi
  for game in "$@"; do build "$game"; done
  echo "done"
  exit 0
fi

# ---------------------------------------------------------------- from GitHub
FORCED=$#    # naming games, or "all", rebuilds them whether or not they have changed
if [ $# -eq 0 ] || [ "$1" = all ]; then set -- $ALL_GAMES; fi
for game in "$@"; do repo_of "$game" > /dev/null; done   # stop now if a name is wrong
rm -rf "$SITE/.sources"
mkdir -p "$SITE/.sources"
UPDATED=$SITE/.sources/updated.txt    # one line for each game that was rebuilt, for whoever commits them
: > "$UPDATED"
failed=
for game in "$@"; do
  repo=$(repo_of "$game")
  had=$(built_from "$game")
  if [ "$FORCED" -eq 0 ] && [ -n "$had" ] && [ "$(latest_of "$repo")" = "$had" ]; then
    echo "$game is up to date ($repo $(echo "$had" | cut -c1-7))"
    continue
  fi
  # In a subshell, so that a game that will not build stops only itself.
  set +e
  ( set -e; build "$game" )
  status=$?
  set -e
  if [ $status -ne 0 ]; then
    echo "FAILED to build $game; its copy in the site is unchanged" >&2
    failed="$failed $game"
    continue
  fi
  was=unrecorded
  [ -z "$had" ] || was=$(echo "$had" | cut -c1-7)
  echo "$game: $repo $was -> $(built_from "$game" | cut -c1-7)" >> "$UPDATED"
done
if [ -n "$failed" ]; then
  echo "could not build:$failed" >&2
  exit 1
fi
echo "done"
