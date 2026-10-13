--!strict
--!native
--!optimize 2
-- Port of make_atlas.sh as a reusable package API.
local magick = require '@magick'

local Atlas = {}

type Image = magick.Image

--- What an atlas is made from: a picture, where the atlas is written, and its grid. Without
--- `mask` each tile is the picture rolled further. With it each tile after the first hides more
--- of the picture, by rows from the top or, with `width`, by columns from the left: blackened,
--- or with `delete` cleared. A switch is on only when it is `true`.
export type Options = {
  input: string?,
  output: string?,
  rows: number?,
  cols: number?,
  mask: boolean?,
  width: boolean?,
  delete: boolean?,
}

export type Result = { output: string, width: number, height: number, rows: number, cols: number, tiles: number }

--- A copy of a picture with the pixels of a rectangle at its top left corner made black, each
--- keeping its alpha.
local function blackened(source: Image, width: number, height: number): Image
  local tile = source:clone()

  for row = 0, height - 1 do
    for column = 0, width - 1 do
      local _, _, _, alpha = tile:get(column, row)

      tile:set(column, row, 0, 0, 0, alpha)
    end
  end

  return tile
end

--- The tile at a place, counted from zero, in an atlas of `total` tiles.
local function tileAt(
  source: Image,
  place: number,
  total: number,
  mask: boolean,
  byWidth: boolean,
  delete: boolean
): Image
  local {width, height} = source

  if not mask then
    -- Rolled down, and by a share of the picture's width whatever its height is.
    return source:roll(0, if total <= 1 then 0 else math.floor(place * width / (total - 1)))
  end

  if place == 0 then return source:clone() end

  local percent = if total <= 1 then 100 else math.floor(place * 100 / (total - 1))
  local hiddenColumns, hiddenRows = math.floor(percent * width / 100), math.floor(percent * height / 100)

  if not delete then
    return if byWidth then blackened(source, hiddenColumns, height) else blackened(source, width, hiddenRows)
  end

  local tile = magick.new(width, height)

  if place == total - 1 then return tile end

  if byWidth then
    local kept = width - hiddenColumns

    if kept > 0 then tile:over(source:crop(kept, height, hiddenColumns, 0), hiddenColumns, 0) end
  else
    local kept = height - hiddenRows

    if kept > 0 then tile:over(source:crop(width, kept, 0, hiddenRows), 0, hiddenRows) end
  end

  return tile
end

function Atlas.generate(options: Options?): Result
  local settings: Options = options or {}
  local input = assert(settings.input, 'atlas: input required')
  local output = assert(settings.output, 'atlas: output required')
  local rows = assert(settings.rows, 'atlas: rows required')
  local columns = assert(settings.cols, 'atlas: cols required')
  local mask, byWidth, delete = settings.mask == true, settings.width == true, settings.delete == true
  local source = magick.read(input)
  local total = rows * columns
  local tiles: { Image } = {}

  for place = 0, total - 1 do
    table.insert(tiles, tileAt(source, place, total, mask, byWidth, delete))
  end

  local atlas = magick.montage(tiles, columns, rows)

  magick.write(output, atlas)

  return { output = output, width = atlas.width, height = atlas.height, rows = rows, cols = columns, tiles = total }
end

return Atlas
