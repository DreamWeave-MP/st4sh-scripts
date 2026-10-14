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
