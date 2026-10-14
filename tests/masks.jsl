--!strict
--!native
-- The masks the package carries, pinned: the geometry and the bytes of every one, what each
-- module says of a name it does not have, and that a mask asked for twice is two buffers.
local bytes = require '@dream/bytes'
local cod3xMasks = require '@st4sh/scripts.cod3x-masks'
local fontMasks = require '@st4sh/scripts.morrowind-font-masks'
local goldens = require './goldens'
local h3Masks = require '@st4sh/scripts.h3-masks'
local oracleMasks = require '@st4sh/scripts.morrowind-oracle-masks'
local spiralMasks = require '@st4sh/scripts.morrowind-spiral-masks'
local support = require './support'
local test = require '@jess/test'

local expect = test.expect
local suite = test.new()
local pin, settle = support.goldens(goldens.masks)

type Mask = { width: number, height: number, data: buffer }

local Fonts = { 'DejaVuLGCSansMono', 'DemonicLetters', 'MysticCards' }
local MenuLabels = { 'Credits', 'Exit', 'Load', 'New', 'Options', 'Papa_Bless', 'Return', 'Save' }

local JournalLabels = {
  'Active',
  'All',
  'Cancel',
  'Close',
  'Journal',
  'Next',
  'Options',
  'Prev',
  'Quests',
  'Take',
  'Topics',
}

local H3Names = {
  'header.left_text',
  'header.h3_full',
  'header.approved',
  'logo.text',
  'logo.h3_full',
  'logo.icon_h3_full',
  'logo.stamp',
  'logo.purple_note',
}

local Cod3xNames = {
  'hero.meta',
  'hero.sub',
  'hero.tag',
  'hero.title',
  'mark.badge.c3',
  'mark.badge.desc',
  'mark.badge.meta',
  'mark.badge.name',
  'mark.badge.tag',
  'mark.icon.c3',
  'mark.icon.name',
  'mark.icon.tag',
  'scope.kicker',
  'scope.sub',
  'scope.title',
}

local OracleNames = {
  'equip_frame_base',
  'enchant_frame_base',
  'tx_cursor',
  'omw_menu_scroll_up',
  'omw_menu_scroll_down',
  'omw_menu_scroll_left',
  'omw_menu_scroll_right',
  'menu_icon_magic_equip_spiral',
  'menu_icon_magic_equip_spiral_large',
}

--- The geometry of a mask and the CRC-32 of its coverage.
local function pixels(mask: Mask): string
  return `{mask.width}x{mask.height}:{string.format('%08x', bytes.crc32(mask.data))}`
end

suite.afterEach(settle)

suite.describe('font masks', function()
  for _, font in Fonts do
    suite.it(`holds the journal labels of {font}`, function()
      local lines: { string } = {}

      for _, label in JournalLabels do
        local key = `{font}|j|16|{label}|0`

        expect(fontMasks.has(key)).toBe(true)
        table.insert(lines, `{key} {pixels(fontMasks.get(key))}`)
      end

      pin(`font {font} journal`, support.digest(table.concat(lines, '\n')))
    end)

    for _, kind in { 'p', 'pfull' } do
      suite.it(`holds the menu labels of {font} as {kind}`, function()
        local lines: { string } = {}

        for _, size in { 14, 32 } do
          for _, label in MenuLabels do
            for _, rotation in { 0, 20 } do
              local key = `{font}|{kind}|{size}|{label}|{rotation}`
              local mask = fontMasks.get(key)

              expect(mask.width).toBe(128)
              expect(mask.height).toBe(64)
              table.insert(lines, `{key} {pixels(mask)}`)
            end
          end
        end

        pin(`font {font} {kind}`, support.digest(table.concat(lines, '\n')))
      end)
    end
  end

  suite.it('knows which masks it has, and refuses one it does not', function()
    expect(fontMasks.has 'MysticCards|j|16|Take|0').toBe(true)
    expect(fontMasks.has 'MysticCards|j|16|Take|20').toBe(false)
    expect(fontMasks.has 'Arial|j|16|Take|0').toBe(false)

    expect(function()
      fontMasks.get 'Arial|j|16|Take|0'
    end).toThrow 'unknown bundled font mask: Arial|j|16|Take|0'
  end)

  suite.it('inflates a mask afresh for every call', function()
    local first, second = fontMasks.get 'MysticCards|j|16|Take|0', fontMasks.get 'MysticCards|j|16|Take|0'

    expect(first == second).toBe(false)
    expect(first.data == second.data).toBe(false)
    buffer.fill(first.data, 0, 255)
    expect(pixels(fontMasks.get 'MysticCards|j|16|Take|0')).toBe(pixels(second))
  end)
end)

suite.describe('h3 masks', function()
  for _, name in H3Names do
    suite.it(`holds {name}`, function()
      pin(`h3 {name}`, pixels(h3Masks.get(name)))
    end)
  end

  suite.it('refuses a name it does not have', function()
    expect(function()
      h3Masks.get 'header.missing'
    end).toThrow 'unknown h3 mask: header.missing'

    expect(function()
      (h3Masks.get :: (name: unknown) -> Mask)(nil)
    end).toThrow 'unknown h3 mask: nil'
  end)

  suite.it('inflates a mask afresh for every call', function()
    expect(h3Masks.get('header.approved').data == h3Masks.get('header.approved').data).toBe(false)
  end)
end)

suite.describe('cod3x masks', function()
  for _, name in Cod3xNames do
    suite.it(`holds {name}`, function()
      pin(`cod3x {name}`, pixels(cod3xMasks.get(name)))
    end)
  end

  suite.it('holds the title and the detail of six cards', function()
    for card = 0, 5 do
      pin(`cod3x scope.card.title.{card}`, pixels(cod3xMasks.get(`scope.card.title.{card}`)))
      pin(`cod3x scope.card.detail.{card}`, pixels(cod3xMasks.get(`scope.card.detail.{card}`)))
    end
  end)

  suite.it('refuses a name it does not have', function()
    expect(function()
      cod3xMasks.get 'scope.card.title.6'
    end).toThrow 'unknown COD3X mask: scope.card.title.6'

    expect(function()
      (cod3xMasks.get :: (name: unknown) -> Mask)(nil)
    end).toThrow 'unknown COD3X mask: nil'
  end)

  suite.it('inflates a mask afresh for every call', function()
    expect(cod3xMasks.get('mark.icon.tag').data == cod3xMasks.get('mark.icon.tag').data).toBe(false)
  end)
end)

suite.describe('oracle and spiral masks', function()
  for _, name in OracleNames do
    suite.it(`holds the oracle's {name}`, function()
      pin(`oracle {name}`, pixels(oracleMasks.get(name)))
    end)
  end

  for _, name in { 'enchant_frame_spiral', 'enchant_frame_spiral_large' } do
    suite.it(`holds the spiral {name}`, function()
      local mask = spiralMasks.get(name)

      expect(mask.width).toBe(44)
      expect(mask.height).toBe(44)
      pin(`spiral {name}`, pixels(mask))
    end)
  end

  suite.it('refuses a name it does not have', function()
    expect(function()
      oracleMasks.get 'tx_pointer'
    end).toThrow 'unknown oracle mask: tx_pointer'

    expect(function()
      spiralMasks.get 'enchant_frame_helix'
    end).toThrow 'unknown spiral template enchant_frame_helix'
  end)

  suite.it('inflates a mask afresh for every call', function()
    expect(oracleMasks.get('tx_cursor').data == oracleMasks.get('tx_cursor').data).toBe(false)

    expect(spiralMasks.get('enchant_frame_spiral').data == spiralMasks.get('enchant_frame_spiral').data).toBe(
      false
    )
  end)
end)

return suite
