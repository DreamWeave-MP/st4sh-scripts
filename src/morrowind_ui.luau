--!strict
--!native
--!optimize 2
-- Port of generate_menu.sh to Jess/Luau. No subprocesses; all raster work is @magick.
local dataPlane = require '@dream/data'
local fontMasks = require '@st4sh/scripts.morrowind-font-masks'
local magick = require '@magick'
local oracleMasks = require '@st4sh/scripts.morrowind-oracle-masks'
local spiralMasks = require '@st4sh/scripts.morrowind-spiral-masks'

local Menu = {}

type Image = magick.Image
type Mask = magick.Mask
type Color = magick.Color
type Source = magick.Source

--- The folder the textures are written into (`Textures` where the process stands, when not
--- given), the theme's three colors, one of the bundled fonts by any of its names, the sizes of
--- the menu's text (14 or 32) and of the journal's (16), and the seed of the noise.
export type Options = {
  output: string?,
  primary: Color?,
  secondary: Color?,
  tertiary: Color?,
  font: string?,
  primarySize: number?,
  secondarySize: number?,
  seed: number?,
}

export type Result = {
  output: string,
  files: number,
  seed: number,
  font: string,
  primarySize: number,
  secondarySize: number,
}

--- A theme `generateAll` makes: the folder it is named for, and what of `Options` it sets.
export type Theme = {
  name: string,
  primary: string?,
  secondary: string?,
  tertiary: string?,
  primarySize: number?,
}

--- The font every theme is made in, and the seed the themes' own seeds are counted from.
export type AllOptions = { font: string?, seed: number? }

--- A state of a button: what its file's name ends in, how far its text is turned, and the tile
--- its text is painted from.
type State = { suffix: string, rotation: number, tile: Image }

local MenuLabels = { 'Credits', 'Exit', 'Load', 'New', 'Options', 'Save', 'Return', 'Papa_Bless' }

--- The file names of the menu buttons that are not named for their labels.
local MenuNames: { [string]: string } = { Save = 'savegame', New = 'newgame', Load = 'loadgame', Exit = 'exitgame' }

local JournalLabels = {
  'Cancel',
  'Close',
  'Journal',
  'Next',
  'Options',
  'Prev',
  'Quests',
  'All',
  'Active',
  'Topics',
  'Take',
}

--- The file names of the journal buttons that are not named for their labels.
local JournalNames: { [string]: string } = { All = 'quests_all', Active = 'quests_active' }

--- Each spiral by the mask it is painted from, the icon it is laid on, and the icon it is laid
--- on with the equip frame.
local Spirals = {
  { mask = 'enchant_frame_spiral', icon = 'menu_icon_magic_spiral', equipped = 'menu_icon_magic_equip_spiral' },
  {
    mask = 'enchant_frame_spiral_large',
    icon = 'menu_icon_magic_spiral_large',
    equipped = 'menu_icon_magic_equip_spiral_large',
  },
}

local function canonicalFont(name: string?): string
  local folded = string.lower(name or 'MysticCards')

  if folded == 'mysticcards' or folded == 'mystic cards' then return 'MysticCards' end

  if folded == 'dejavulgcsansmono' or folded == 'dejavulgcsansmono.ttf' or folded == 'dejavu lgc sans mono' then
    return 'DejaVuLGCSansMono'
  end

  if folded == 'demonicletters' or folded == 'demonicletters.ttf' or folded == 'demonic letters' then
    return 'DemonicLetters'
  end

  error('morrowind-ui: bundled font must be MysticCards, DejaVuLGCSansMono, or DemonicLetters', 2)
end

local function ensureDir(path: string)
  if not jess.fs.exists(path) then
    jess.fs.createDir(path)
  elseif not jess.fs.isDir(path) then
    error(path .. ' exists and is not a directory', 2)
  end
end

--- A mask of whichever of two masks covers each pixel more.
local function maxMask(first: Mask, second: Mask): Mask
  local count = first.width * first.height
  local out = buffer.create(count)

  for index = 0, count - 1 do
    buffer.writeu8(out, index, math.max(buffer.readu8(first.data, index), buffer.readu8(second.data, index)))
  end

  return magick.mask(first.width, first.height, out)
end

--- A mask with its coverage scaled, each byte rounded.
local function scaleMaskAlpha(mask: Mask, amount: number): Mask
  local count = mask.width * mask.height
  local out = buffer.create(count)

  for index = 0, count - 1 do
    buffer.writeu8(out, index, math.floor(buffer.readu8(mask.data, index) * amount + 0.5))
  end

  return magick.mask(mask.width, mask.height, out)
end

--- 0, 1, 2 ... as u32s: the index vector that scatters a mask's bytes one to a pixel. Grown to the
--- largest image asked of it, and never shrunk.
local identity = buffer.create(0)

local function positions(count: number): buffer
  if buffer.len(identity) >= count * 4 then return identity end

  identity = buffer.create(count * 4)
  into(identity, 'u32')[for index in range(0, count - 1) => index]

  return identity
end

--- Gives every pixel of an image the coverage a mask of its size has there as its alpha.
local function applyAlpha(image: Image, mask: Mask)
  assert(image.width == mask.width and image.height == mask.height, 'alpha mask geometry mismatch')

  local count = image.width * image.height
  dataPlane.scatter(mask.data, 'u8@4+3', 0, count, positions(count), image.data, 0, count)
end

local function write(folder: string, name: string, image: Image)
  magick.writeDDS(jess.fs.join(folder, name .. '.dds'), image)
end

--- A label of the menu (`p`) or of the journal (`j`) painted from a tile. With a stroke or a
--- shadow the text is laid over its outline in the secondary color, and that over the outline's
--- blurred shadow; a menu label then takes the alpha the oracle gave the whole of it.
local function textImage(
  font: string,
  kind: string,
  size: number,
  label: string,
  rotation: number,
  tile: Image,
  secondary: Color,
  strokeWidth: number,
  shadowRadius: number,
  shadowOpacity: number
): Image
  local mask = fontMasks.get(`{font}|{kind}|{size}|{label}|{rotation}`)

  if strokeWidth <= 0 and shadowOpacity <= 0 then return magick.paintMask(mask, tile) end

  local stroke = magick.dilateMask(mask, math.max(1, math.floor(strokeWidth + 0.5)))
  local paintedStroke, paintedFill = magick.paintMask(stroke, secondary), magick.paintMask(mask, tile)
  local out = magick.new(mask.width, mask.height)

  if shadowOpacity > 0 then
    local blurred = magick.blurMask(maxMask(mask, stroke), shadowRadius)

    out:over(magick.paintMask(scaleMaskAlpha(blurred, shadowOpacity / 100), secondary))
  end

  out:over(paintedStroke)
  out:over(paintedFill)

  if kind == 'p' then applyAlpha(out, fontMasks.get(`{font}|pfull|{size}|{label}|{rotation}`)) end

  return out
end

--- The textures of a frame around a rectangle of a size: the frame whole, hollow and as its
--- center, then the hollow frame's sides, their middles and its corners.
local function frameTextures(
  folder: string,
  innerWidth: number,
  innerHeight: number,
  thickness: number,
  dark: Source,
  light: Source,
  name: string,
  cornerSuffix: string?
)
  local width, height = innerWidth + thickness * 2, innerHeight + thickness * 2
  local border = thickness * 2
  local solid = magick.new(width, height)

  solid:rect(0, 0, width - 1, height - 1, dark)
  solid:rect(thickness, thickness, innerWidth + thickness - 1, innerHeight + thickness - 1, light)
  write(folder, name .. '_solid', solid)

  local hollow = solid:clone()

  local first, last = math.max(border, 0), math.min(innerWidth, width) - 1

  if last >= first then
    for row = math.max(border, 0), math.min(innerHeight, height) - 1 do
      dataPlane.fill(hollow.data, 'u8@4+3', (row * width + first) * 4, last - first + 1, 0)
    end
  end

  write(folder, name .. '_hollow', hollow)
  write(folder, name .. '_center', solid:crop(innerWidth - border, innerHeight - border, border, border))

  local middleWidth, middleHeight = innerWidth - border, innerHeight - border
  local leftSide, rightSide = hollow:crop(border, height, 0, 0), hollow:crop(border, height, innerWidth, 0)

  write(folder, name .. '_left_side', leftSide)
  write(folder, name .. '_right_side', rightSide)
  write(folder, name .. '_left', leftSide:crop(border, middleHeight, 0, border))
  write(folder, name .. '_right', rightSide:crop(border, middleHeight, 0, border))

  local topSide, bottomSide = hollow:crop(width, border, 0, 0), hollow:crop(width, border, 0, innerHeight)

  write(folder, name .. '_top_side', topSide)
  write(folder, name .. '_bottom_side', bottomSide)
  write(folder, name .. '_top', topSide:crop(middleWidth, border, border, 0))
  write(folder, name .. '_bottom', bottomSide:crop(middleWidth, border, border, 0))

  local suffix = cornerSuffix or '_corner'

  write(folder, name .. '_top_left' .. suffix, topSide:crop(border, border, 0, 0))
  write(folder, name .. '_top_right' .. suffix, topSide:crop(border, border, innerWidth, 0))
  write(folder, name .. '_bottom_left' .. suffix, bottomSide:crop(border, border, 0, 0))
  write(folder, name .. '_bottom_right' .. suffix, bottomSide:crop(border, border, innerWidth, 0))
end

--- A square of a tile whose alpha falls away from its center to nothing at its corners.
local function radialTile(tile: Image, size: number): Image
  local out = magick.new(size, size)
  local center = (size - 1) / 2
  local farthest = math.sqrt(center * center + center * center)

  for row = 0, size - 1 do
    for column = 0, size - 1 do
      local red, green, blue, alpha = tile:get(column % tile.width, row % tile.height)
      local across, down = column - center, row - center
      local share = math.max(0, 1 - math.sqrt(across * across + down * down) / farthest)

      out:set(column, row, red, green, blue, alpha * share)
    end
  end

  return out
end

local function iconSet(folder: string, active: Image, highlight: Image, secondary: Color)
  local equip = magick.new(39, 39)

  equip:rect(0, 0, 38, 38, highlight)
  equip:rect(1, 1, 37, 37, active)

  -- DstOut a 14px radius circle centered at (19,19).
  for row = 0, 38 do
    for column = 0, 38 do
      local across, down = column - 19, row - 19

      if across * across + down * down <= 14 * 14 then
        local red, green, blue = equip:get(column, row)

        equip:set(column, row, red, green, blue, 0)
      end
    end
  end

  applyAlpha(equip, oracleMasks.get 'equip_frame_base')
  write(folder, 'equip_frame_base', equip)

  local menuEquip = magick.new(64, 64)

  menuEquip:over(equip, 2, 2)
  write(folder, 'menu_icon_equip', menuEquip)

  local enchantBase = radialTile(highlight, 43)

  applyAlpha(enchantBase, oracleMasks.get 'enchant_frame_base')
  write(folder, 'enchant_frame_base', enchantBase)

  local magicIcon = magick.new(64, 64)

  magicIcon:over(enchantBase, 0, 0)
  write(folder, 'menu_icon_magic', magicIcon)

  local magicEquip, framed = magick.new(64, 64), magick.new(39, 39)

  framed:over(enchantBase:resize(43, 43, true):crop(39, 39, 2, 2))
  framed:over(equip)
  magicEquip:over(framed, 2, 2)
  write(folder, 'menu_icon_magic_equip', magicEquip)

  for _, names in Spirals do
    local spiral = magick.paintMask(spiralMasks.get(names.mask), secondary)
    local icon, equipped, combined = magick.new(64, 64), magick.new(64, 64), magick.new(39, 39)

    write(folder, names.mask, spiral)
    icon:over(spiral, 0, 0)
    write(folder, names.icon, icon)
    combined:over(spiral:resize(43, 43, true):crop(39, 39, 2, 2))
    combined:over(equip)
    equipped:over(combined, 2, 2)
    applyAlpha(equipped, oracleMasks.get(names.equipped))
    write(folder, names.equipped, equipped)
  end
end

local function scrollbars(folder: string, active: Image, highlight: Image, seed: number)
  local center = active:crop(16, 32, (seed * 37) % (512 - 16), (seed * 91) % (512 - 32))

  write(folder, 'omw_menu_scroll_center_h', center)
  write(folder, 'omw_menu_scroll_center_v', center:rotate90(true))

  local up = magick.new(16, 16)

  up:polygon({ { 0, 14 }, { 14, 14 }, { 7, 1 } }, highlight)
  up:polygon({ { 1, 13 }, { 13, 13 }, { 7, 2 } }, active)
  applyAlpha(up, oracleMasks.get 'omw_menu_scroll_up')
  write(folder, 'omw_menu_scroll_up', up)

  local left = up:rotate90(false)

  applyAlpha(left, oracleMasks.get 'omw_menu_scroll_left')
  write(folder, 'omw_menu_scroll_left', left)

  local right = up:rotate90(true)

  applyAlpha(right, oracleMasks.get 'omw_menu_scroll_right')
  write(folder, 'omw_menu_scroll_right', right)

  local down = magick.new(16, 16)

  down:polygon({ { 0, 1 }, { 14, 1 }, { 7, 14 } }, highlight)
  down:polygon({ { 1, 2 }, { 13, 2 }, { 7, 13 } }, active)
  applyAlpha(down, oracleMasks.get 'omw_menu_scroll_down')
  write(folder, 'omw_menu_scroll_down', down)
end

function Menu.generate(options: Options?): Result
  local settings: Options = options or {}
  local folder = settings.output or 'Textures'

  ensureDir(folder)

  local primary = magick.color(settings.primary or '#b20047')
  local secondary = magick.color(settings.secondary or '#00ff99')
  local tertiary = magick.color(settings.tertiary or '#ff4d94')
  local font = canonicalFont(settings.font or 'MysticCards')
  local primarySize, secondarySize = settings.primarySize or 32, settings.secondarySize or 16

  if primarySize ~= 14 and primarySize ~= 32 then
    error('morrowind-ui: compiled oracle masks currently support primarySize 14 or 32', 2)
  end

  if secondarySize ~= 16 then
    error('morrowind-ui: compiled oracle masks currently support secondarySize 16', 2)
  end

  local seed = math.floor(settings.seed or 0x4A455353)
  local base = magick.noise(512, 512, primary, seed + 1, 0.25)
  local highlight = magick.noise(512, 512, secondary, seed + 2, 0.25)
  local active = magick.noise(512, 512, tertiary, seed + 3, 0.25)

  write(folder, 'noise_base', base)
  write(folder, 'noise_highlight', highlight)
  write(folder, 'noise_active', active)

  local menuStates: { State } = {
    { suffix = '', rotation = 0, tile = base },
    { suffix = '_pressed', rotation = 20, tile = active },
    { suffix = '_over', rotation = 20, tile = base },
  }

  local journalStates: { State } = {
    { suffix = '_idle', rotation = 0, tile = active },
    { suffix = '_pressed', rotation = 0, tile = base },
    { suffix = '_over', rotation = 0, tile = highlight },
  }

  for _, label in MenuLabels do
    for _, state in menuStates do
      local image = textImage(font, 'p', primarySize, label, state.rotation, state.tile, secondary, 1, 5, 40)

      write(folder, 'menu_' .. (MenuNames[label] or label) .. state.suffix, image)
    end
  end

  for _, label in JournalLabels do
    for _, state in journalStates do
      local image = textImage(font, 'j', secondarySize, label, state.rotation, state.tile, secondary, 0, 0, 0)

      write(folder, 'tx_menubook_' .. (JournalNames[label] or label) .. state.suffix, image)
    end
  end

  scrollbars(folder, active, highlight, seed)
  iconSet(folder, active, highlight, secondary)

  frameTextures(folder, 512, 512, 1, active, highlight, 'menu_thin_border')
  frameTextures(folder, 512, 512, 2, active, highlight, 'menu_thick_border')
  frameTextures(folder, 256, 16, 1, highlight, active, 'menu_head_block')
  -- Match the original's odd rename of center -> middle.
  jess.fs.copy(jess.fs.join(folder, 'menu_head_block_center.dds'), jess.fs.join(folder, 'menu_head_block_middle.dds'))
  jess.fs.remove(jess.fs.join(folder, 'menu_head_block_center.dds'))
  frameTextures(folder, 128, 16, 4, active, highlight, 'menu_button_frame')
  frameTextures(folder, 12, 12, 2, highlight, active, 'menu_rightbuttondown', '')
  frameTextures(folder, 12, 12, 2, active, highlight, 'menu_rightbuttonup', '')

  frameTextures(folder, 120, 120, 4, active, highlight, 'extra_frame_128_thick')
  frameTextures(folder, 124, 124, 2, active, highlight, 'extra_frame_128_thin')
  frameTextures(folder, 64, 64, 4, active, highlight, 'extra_frame_72_thick')
  frameTextures(folder, 68, 68, 2, active, highlight, 'extra_frame_72_thin')
  frameTextures(folder, 24, 24, 4, active, highlight, 'extra_frame_36_thick')
  frameTextures(folder, 32, 32, 2, active, highlight, 'extra_frame_36_thin')
  frameTextures(folder, 28, 28, 2, active, highlight, 'extra_frame_32_thin')
  frameTextures(folder, 24, 24, 4, active, highlight, 'extra_frame_32_thick')
  frameTextures(folder, 16, 16, 1, active, highlight, 'extra_frame_18_thin')
  frameTextures(folder, 14, 14, 2, active, highlight, 'extra_frame_18_thick')

  -- The oracle supplies IM's exact antialiased rotate/emboss silhouette; theme color stays live.
  write(folder, 'tx_cursor', magick.paintMask(oracleMasks.get 'tx_cursor', active))

  return {
    output = folder,
    files = #jess.fs.list(folder),
    seed = seed,
    font = font,
    primarySize = primarySize,
    secondarySize = secondarySize,
  }
end

Menu.themes = {
  { name = 'ArcaneEnergy', primary = 'AA00FF', tertiary = '5500AA', secondary = 'E040FB' },
  { name = 'MysticOcean', primary = '0074d9', secondary = '001f3f', tertiary = '7fdbff' },
  { name = 'momw', primary = '222', secondary = '444', tertiary = '333' },
  { name = 'Prim', primary = 'f1ecf6', secondary = '7a49a5', tertiary = 'd7c8e4' },
  { name = 'PickleRick', primary = 'a3ffb4', tertiary = '4974a5', secondary = '304c36' },
  { name = 'White-Rose', primary = '843c54', tertiary = '5c2a3a', secondary = '271219' },
  { name = 'Beige', primary = 'ffa500', tertiary = '4974a5', secondary = 'fff6e5' },
  { name = 'America', primary = 'fff', tertiary = 'f00', secondary = '00f' },
  { name = 'Rose' },
  { name = 'Royale', primary = '000', tertiary = '180e21', secondary = '492b63' },
  { name = 'Blood-Raven', primary = 'ff0000', tertiary = '190000', secondary = '000000' },
  { name = 'Mono', primary = '000', secondary = '333', tertiary = 'fff' },
  { name = 'VeryDark', primary = 'fff', secondary = '333', tertiary = '111' },
  { name = 'Cobalt', primary = '000000', secondary = '0066ff', tertiary = '002866', primarySize = 14 },
  { name = 'IndustrialSteel', tertiary = '3d3d3d', secondary = '7f8c8d', primary = 'bdc3c7' },
} :: { Theme }

function Menu.generateAll(root: string?, options: AllOptions?): { Result }
  local parent = root or '.'
  local settings: AllOptions = options or {}
  local results: { Result } = {}

  ensureDir(parent)

  for index, theme in Menu.themes do
    local folder = jess.fs.join(parent, theme.name, 'Textures')

    ensureDir(jess.fs.join(parent, theme.name))

    if jess.fs.exists(folder) then
      for _, name in jess.fs.list(folder) do
        jess.fs.remove(jess.fs.join(folder, name))
      end
    else
      ensureDir(folder)
    end

    table.insert(
      results,
      Menu.generate {
        output = folder,
        primary = theme.primary,
        secondary = theme.secondary,
        tertiary = theme.tertiary,
        primarySize = theme.primarySize,
        font = settings.font,
        seed = (settings.seed or 0x4A455353) + index * 1000,
      }
    )
  end

  return results
end

return Menu
