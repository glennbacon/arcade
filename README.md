# Arcade

Five games by Glenn Bacon that play in the browser, on a phone or a desktop, with nothing to install.

**[Open the arcade](https://glennbacon.github.io/arcade/)**

![The arcade page: a card for each of the five games under the word ARCADE](screenshot.png)

## The games

| Game | What it is | Play | Source |
|---|---|---|---|
| **Super Daddio** | A side-scrolling platformer from 2012, ported to the browser. 60 levels across nine worlds. | [Play](https://glennbacon.github.io/arcade/super-daddio/) | [superdaddio](https://github.com/glennbacon/superdaddio), in `web/` |
| **Super Daddio 3D** | The same game remade as a voxel diorama. | [Play](https://glennbacon.github.io/arcade/super-daddio-voxel/) | [superdaddio](https://github.com/glennbacon/superdaddio), in `voxel/` |
| **Blorp's Big Romp** | A voxel platformer. Six worlds, thirty levels and a map to walk between them. | [Play](https://glennbacon.github.io/arcade/blorps-big-romp/) | [blorps-big-romp](https://github.com/glennbacon/blorps-big-romp) |
| **Blorp's Big Romp 2** | Its sequel. Eight worlds, forty levels and 120 moon shards to find. | [Play](https://glennbacon.github.io/arcade/blorps-big-romp-2/) | [blorps-big-romp2](https://github.com/glennbacon/blorps-big-romp2) |
| **Amped Ascent** | An electric hill-climb driving game. Endless runs, a 90-level adventure, a garage and a level editor. | [Play](https://glennbacon.github.io/arcade/amped-ascent/) | [AmpedAscent](https://github.com/glennbacon/AmpedAscent) |

## What is where

This is a plain static site. GitHub Pages serves the repository as it is; the page itself has no
build step and no scripts.

| Path | What it holds |
|---|---|
| `index.html` | The arcade page, with its styles |
| `assets/` | The picture on each game's card, and the picture shown when a link to the arcade is shared |
| `super-daddio/`, `super-daddio-voxel/`, `blorps-big-romp/`, `blorps-big-romp-2/`, `amped-ascent/` | A built copy of each game |
| `build.sh` | Rebuilds those copies from the games' repositories |
| `screenshot.png` | The picture at the top of this page |
| `.nojekyll` | Tells GitHub Pages to publish the files untouched |

The games are developed in their own repositories. The five folders here hold only what their
builds produce, so do not edit them by hand: change the game in its repository, then update its
copy here.

## Updating a game

```bash
./build.sh                 # every game
./build.sh amped-ascent    # only the ones named
```

This needs bash, git and [Node.js](https://nodejs.org/) 22 or newer. The script looks for the game
repositories next to this one (`../superdaddio`, `../blorps-big-romp`, `../blorps-big-romp2`,
`../AmpedAscent`); set `GAMES_DIR` to look somewhere else. A repository that is not there is cloned
from GitHub into `.sources/`, which git ignores. It builds whatever is checked out, so check out the
version you want to publish first.

Then commit the folders that changed and push. GitHub Pages publishes the new copy.

To look at the site before pushing, serve this folder and open <http://localhost:8000>:

```bash
python3 -m http.server
```

## Adding a game

1. Add a line for it to the `build` function in `build.sh`, and its name to the list near the end.
2. Put an 800 × 480 picture of it in `assets/`.
3. Copy one of the `<li class="game">` blocks in `index.html`, and change the picture, the text, the
   links and `--accent`, the card's colour.

The cards sit three to a row with the last row centred. That is written for five cards: with a
different number, change the `.game:nth-child` rules in the page's styles.

## Publishing

In the repository's settings on GitHub, under **Pages**, choose **Deploy from a branch**, pick the
branch and the folder `/ (root)`. The site is then at <https://glennbacon.github.io/arcade/>, and
each game at its folder's name under that.

## Licence

**The arcade page and `build.sh` — MIT.** See [`LICENSE`](LICENSE).

**The games.** Each game's folder is a build of its repository and comes under that repository's
licence. The code of all of them is MIT.

**Super Daddio's artwork, sound effects and music — not MIT.** They are in `super-daddio/` and
`super-daddio-voxel/`, and the pictures of the two games in `assets/` and `screenshot.png` show them.
They belong to Glenn Bacon and may be used for non-commercial purposes only; the terms are in
[`LICENSE-ASSETS.md`](https://github.com/glennbacon/superdaddio/blob/main/LICENSE-ASSETS.md) in the
Super Daddio repository.

**Other people's work.** The built games include [three.js](https://github.com/mrdoob/three.js) and
[planck.js](https://github.com/piqnt/planck.js), both MIT, and Super Daddio includes the "Pixelated"
typeface, copyright © 2007 Galactic Federation Fontworks. The two Blorp games load three.js and
their fonts from CDNs; the arcade page loads [Pixelify Sans](https://fonts.google.com/specimen/Pixelify+Sans)
(SIL Open Font License) from Google Fonts.
