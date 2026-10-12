# st4sh-scripts.jpk

Opinionated St4sh graphics/build scripts for Jess. This package owns the Morrowind UI generator, H3/H3UI artwork/chrome tools, COD3X artwork generators, the progressive atlas utility, their CLI parsers, fixed oracle text masks, and bundled font/source attribution.

It depends on `org.dreamweave.magick` for generic raster/codec operations. `magick.jpk` intentionally contains no Morrowind/H3/COD3X policy or assets.

## Modules

- `@st4sh/scripts` — aggregate API.
- `@st4sh/scripts.cli` — parser/dispatcher equivalents of the old loose Luau adapters; call `run(command, args)`.
- `@st4sh/scripts.atlas` — `make_atlas.sh` port.
- `@st4sh/scripts.morrowind-ui` — Morrowind/OpenMW menu texture generation.
- `@st4sh/scripts.morrowind-fucked` — destructive shuffle tool, isolated on purpose.
- `@st4sh/scripts.h3` — H3 header/logo, H3UI material source generation, and chrome recomposition.
- `@st4sh/scripts.cod3x` — COD3X hero/scope/mark generation using the supplied Oxanium coverage oracle.
- `@st4sh/scripts.material-variants` — `build_material_variants.sh` port; catalog/source assets stay caller-owned.

The old `h3-tools.jpk`, `morrowind-ui.jpk`, and loose release `scripts/*.luau` adapters are intentionally gone. Their implementation is consolidated here.

## Codec note

The generic package still does not implement WebP. COD3X `hero` and `mark` therefore emit `nexusHeader.png` and `icon.png` with the same raster content contract rather than pretending PNG bytes are WebP. Native ImageMagick WebP output remains a differential oracle only.
