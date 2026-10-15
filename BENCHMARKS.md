# Benchmarks

Measured on 2026-10-14 on an Intel Core i7-10870H (2.20 GHz, 8 cores), with a verified release
build of Jess at `b12612f` on l3i 2.0.2.

```sh
jess run --capability filesystem.read --capability filesystem.write \
  --package <package> --package-path jpk <package>/bench/bench.jsl <folder on a tmpfs>
```

Base is `92cdf73` (the bench's own commit, before any change it measures); head is `cd0d21c`. The
folder each run wrote into was on a tmpfs, so the times are the generators' work and not the
disk's: `jess.fs.write` syncs every file it writes. Each side ran the whole bench three times,
alternating base and head under one lock, with the same binary and the same `@magick`. Each
figure is the median of the three runs, each run itself the median of seven batches. Every
workload checks the files it wrote, or the masks it inflated, against the fingerprints the package
had as imported, and both sides matched on every row. A difference under 5 percent is noise.

| Workload | Base | Head | Ratio |
|---|---:|---:|---:|
| masks: every font mask | 5.745 ms | 5.956 ms | no change |
| masks: every h3 mask | 4.209 ms | 4.286 ms | no change |
| masks: every cod3x mask | 14.401 ms | 14.623 ms | no change |
| masks: every oracle and spiral mask | 106.7 µs | 106.7 µs | no change |
| morrowind: a menu theme | 121.467 ms | 71.915 ms | 1.69x |
| morrowind: a menu theme, DejaVu at 14 | 118.484 ms | 69.526 ms | 1.70x |
| cod3x: hero | 9.714 ms | 9.575 ms | no change |
| cod3x: scope | 48.826 ms | 46.407 ms | no change |
| cod3x: icon and badge | 57.706 ms | 57.611 ms | no change |
| h3: header, clean and classified | 218.629 ms | 218.857 ms | no change |
| h3: logo icon | 34.416 ms | 34.703 ms | no change |
| h3: chrome sources | 284.672 ms | 253.140 ms | 1.12x |
| h3: recompose H3UI | 5.508 ms | 5.496 ms | no change |
| h3: recompose a Morrowind theme | 5.723 ms | 5.721 ms | no change |
| atlas: sixteen tiles, scrolled | 26.581 ms | 25.767 ms | no change |
| atlas: sixteen tiles, masked by rows | 57.594 ms | 26.531 ms | 2.17x |
| atlas: sixteen tiles, masked by columns | 57.278 ms | 27.429 ms | 2.09x |
| atlas: sixteen tiles, deleted by rows | 25.613 ms | 25.660 ms | no change |
| atlas: sixteen tiles, deleted by columns | 26.983 ms | 27.439 ms | no change |
| variants: one material, with its preview and site data | 300.799 ms | 266.794 ms | 1.13x |
| cli: a command dispatched to a generator with nothing to make | 4.6 µs | 4.4 µs | no change |

The generators spend most of their time inside `@magick`, which has its own A/B. What was
st4sh's own were five loops that changed one channel of a picture a pixel at a time, each through
`get` and `set`. Four of them are now a data-plane call a row at a time over the strided channel
(`'u8@4+3'` is the alpha byte of every RGBA pixel), clipped to the picture as `set` clipped:

- the menu's hollow frames and the H3 frames clear the alpha inside their margin with `fill`;
- the menu gives a picture its mask's coverage as alpha with one `scatter` over the whole picture;
- a masked atlas tile is blackened with three `fill`s a row, its alpha kept.

A menu theme is 1.7 times faster, a masked atlas about twice, and the H3 chrome sources and the
material variants, which build H3 frames, 12 to 13 percent. The fifth loop cuts a circle out of a
39 by 39 badge, where the span of each row would need a square root to find; at 1,521 pixels it
stays a loop. `cod3x: scope` read 1.05 here with no change to anything it calls; it is noise.

The style debt the package was imported with is mostly gone: 841 errors and 164 warnings at
import, 575 and 14 now, of which 554 are double-quoted strings in the five generated mask tables.

## Which modules are native, and why

Jess compiles to machine code only what is marked (`--!native` on a module, `@native` on one
function), and every load pays for what is marked. A module carries `--!native` when a row below
spends its time there and the module is small (12 KB or less); a larger module carries `@native`
on the functions the row spends its time in, and nothing else.

Measured 2026-10-15 with `jess 0.1.0`, the verified release build of jess `07c38cb` on l3i
2.0.3, on the i7-10870H, the one-minute load 1.43 and 1.45 at the start of the two
sessions. In each session the bench ran alternately on this package and on a copy of it with
every module marked, three fresh runs of `bench/bench.jsl` each, every run's row the median of
its batches; a column is the median of the three, and a ratio is against the all-marked runs of
the same session. Which functions a row spends its time in comes from `jess run --profile` of
that row alone, unmarked. The load cost is a fresh `jess run --package <this package>
--package-path jpk` of a script that only requires `@st4sh/scripts`, the two sides alternating, the
median of five each after one warm-up.

| Requiring `@st4sh/scripts` | All marked | This state |
| --- | ---: | ---: |
| Unmarked | 0.094 s | 0.083 s |
| Final | 0.109 s | 0.095 s |

| Row | All marked (ms) | Unmarked / all marked | Final (ms) | Final / all marked |
| --- | ---: | ---: | ---: | ---: |
| masks: every font mask | 5.901 | 0.990× | 6.110 | 1.035× |
| masks: every h3 mask | 4.266 | 0.985× | 4.529 | **1.062×** |
| masks: every cod3x mask | 16.05 | 1.004× | 16.30 | 1.016× |
| masks: every oracle and spiral mask | 0.1064 | **1.061×** | 0.1089 | 1.023× |
| morrowind: a menu theme | 332.4 | 1.019× | 328.8 | 0.989× |
| morrowind: a menu theme, DejaVu at 14 | 330.2 | **1.126×** | 328.7 | 0.996× |
| cod3x: hero | 11.10 | 0.977× | 11.69 | **1.053×** |
| cod3x: scope | 49.25 | 0.992× | 52.29 | **1.062×** |
| cod3x: icon and badge | 62.32 | 0.982× | 64.10 | 1.029× |
| h3: header, clean and classified | 238.2 | 0.987× | 245.7 | 1.031× |
| h3: logo icon | 36.94 | 0.999× | 36.81 | 0.997× |
| h3: chrome sources | 283.7 | 1.002× | 289.9 | 1.022× |
| h3: recompose H3UI | 7.808 | 1.004× | 7.784 | 0.997× |
| h3: recompose a Morrowind theme | 8.035 | 0.959× | 7.703 | 0.959× |
| atlas: sixteen tiles, scrolled | 31.08 | **1.082×** | 30.84 | 0.992× |
| atlas: sixteen tiles, masked by rows | 30.09 | **1.209×** | 30.71 | 1.021× |
| atlas: sixteen tiles, masked by columns | 31.35 | **1.178×** | 31.05 | 0.990× |
| atlas: sixteen tiles, deleted by rows | 28.16 | **1.205×** | 28.70 | 1.019× |
| atlas: sixteen tiles, deleted by columns | 31.62 | **1.185×** | 31.45 | 0.995× |
| variants: one material, with its preview and site data | 303.5 | 0.992× | 298.5 | 0.984× |
| cli: a command dispatched to a generator with nothing to make | 0.00542 | 1.049× | 0.00567 | 1.046× |

What carries the directive (every module and function here is one a row spends its time in,
unmarked):

- Whole: `atlas`, `morrowind_oracle_masks`, `morrowind_spiral_masks`.
- `cod3x_masks`, by function: `M.get`.
- `h3`, by function: `twoTone`.
- `h3_masks`, by function: `M.get`.
- `morrowind_font_masks`, by function: `M.get`.
- `morrowind_ui`, by function: `maxMask`, `scaleMaskAlpha`.
- Unmarked: `cli`, `cod3x`, `init`, `material_variants`, `morrowind_fucked`.

Three of the mask modules are generated data (a table of compressed masks and one `M.get` that
inflates them), 550 KB between them, that every load used to compile to machine code: their
getters carry `@native` and the tables load as bytecode, which is most of the 0.014 s a load this
saves. `morrowind_oracle_masks` and `morrowind_spiral_masks` were unmarked before this pass and
are marked now: their `M.get` is up to 82% of a mask row. `cli` parses a command line once a run
and is never marked. The three rows still above 5% are 1.053x to 1.062x, inside this protocol's
noise: two all-marked copies of dream-archive, measured the same way, put 10 of 109 rows more
than 5% apart, the 95th percentile at 1.074x.
