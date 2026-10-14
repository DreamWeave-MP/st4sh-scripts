--!strict
--!native
-- The Morrowind menu generator and the shuffle beside it, pinned: every file a theme is, by the
-- kind of texture, for each bundled font; what a call answers; what it refuses; and what the
-- shuffle moves, wherever the filesystem's own order of names cannot change the answer.
local goldens = require './goldens'
local shuffle = require '@st4sh/scripts.morrowind-fucked'
local support = require './support'
local test = require '@jess/test'
local ui = require '@st4sh/scripts.morrowind-ui'

local expect = test.expect
local suite = test.new()
local pin, settle = support.goldens(goldens.morrowind)
local scratch = support.scratch

--- The kinds of texture a theme is made of, each by a pattern its file names match.
local Kinds = {
  { name = 'noise', pattern = '^noise_' },
  { name = 'cursor', pattern = '^tx_cursor' },
  { name = 'journal', pattern = '^tx_menubook_' },
  { name = 'scrollbars', pattern = '^omw_menu_scroll_' },
  { name = 'icons', pattern = '^menu_icon_' },
  { name = 'icon bases', pattern = '_frame_base' },
  { name = 'spirals', pattern = '^enchant_frame_spiral' },
  { name = 'thin border', pattern = '^menu_thin_border' },
  { name = 'thick border', pattern = '^menu_thick_border' },
  { name = 'head block', pattern = '^menu_head_block' },
  { name = 'button frame', pattern = '^menu_button_frame' },
  { name = 'right buttons', pattern = '^menu_rightbutton' },
  { name = 'extra frames', pattern = '^extra_frame_' },
  { name = 'pressed', pattern = '_pressed%.dds$' },
  { name = 'over', pattern = '_over%.dds$' },
}

local Themes = {
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
}

--- Removes every file under a folder, so a theme's 13 MB do not outlive the case that read them.
local function discard(folder: string)
  for _, path in support.files(folder) do
    jess.fs.remove(jess.fs.join(folder, path))
  end
end

--- A file of a few bytes, its folder made first.
local function plant(folder: string, name: string, text: string): string
  local path = jess.fs.join(folder, name)

  jess.fs.createDir(folder)
  jess.fs.write(path, text)

  return path
end

suite.afterEach(settle)

suite.describe('generate', function()
  suite.it('makes the default theme, kind by kind', function()
    local out = scratch('ui', 'default')
    local result = ui.generate { output = out }

    expect(result).toEqual {
      output = out,
      files = 318,
      seed = 0x4A455353,
      font = 'MysticCards',
      primarySize = 32,
      secondarySize = 16,
    }

    pin('default', support.folder(out))

    for _, kind in Kinds do
      pin(`default {kind.name}`, support.folder(out, kind.pattern))
    end

    expect(jess.fs.exists(jess.fs.join(out, 'menu_head_block_center.dds'))).toBe(false)
    expect(jess.fs.exists(jess.fs.join(out, 'menu_head_block_middle.dds'))).toBe(true)
    discard(out)
  end)

  suite.it('makes a theme of colors, a seed, the small size and DejaVu', function()
    local out = scratch('ui', 'dejavu')

    local result = ui.generate {
      output = out,
      primary = '#102030',
      secondary = '0f8',
      tertiary = 'c86432ff',
      font = 'DejaVu LGC Sans Mono',
      primarySize = 14,
      secondarySize = 16,
      seed = 77.9,
    }

    expect(result).toEqual {
      output = out,
      files = 318,
      seed = 77,
      font = 'DejaVuLGCSansMono',
      primarySize = 14,
      secondarySize = 16,
    }

    pin('dejavu', support.folder(out))

    for _, kind in Kinds do
      pin(`dejavu {kind.name}`, support.folder(out, kind.pattern))
    end

    discard(out)
  end)

  suite.it('makes a theme in Demonic Letters over what the folder held', function()
    local out = scratch('ui', 'demonic')

    plant(out, 'stale.txt', 'left behind')
    plant(out, 'noise_base.dds', 'replaced')

    local result = ui.generate { output = out, font = 'demonicletters.ttf', seed = 0 }

    expect(result.files).toBe(319)
    expect(result.font).toBe 'DemonicLetters'
    expect(result.seed).toBe(0)
    expect(support.file(jess.fs.join(out, 'stale.txt'))).toBe(support.digest 'left behind')
    pin('demonic', support.folder(out, '%.dds$'))
    pin('demonic journal', support.folder(out, '^tx_menubook_'))
    pin('demonic pressed', support.folder(out, '_pressed%.dds$'))
    discard(out)
  end)

  suite.it('takes every spelling of a bundled font', function()
    local spellings = {
      'mysticcards',
      'MYSTIC CARDS',
      'DejaVuLGCSansMono',
      'dejavulgcsansmono.ttf',
      'DemonicLetters',
      'Demonic Letters',
    }

    -- A size the masks do not carry stops the call after the font is settled and before any
    -- texture is made, so each spelling is held to getting that far.
    for _, name in spellings do
      expect(function()
        ui.generate { output = scratch('ui', 'spellings'), font = name, primarySize = 20 }
      end).toThrow 'morrowind-ui: compiled oracle masks currently support primarySize 14 or 32'
    end
  end)

  suite.it('refuses a font, a size and a folder it cannot use', function()
    local out = scratch('ui', 'refused')

    expect(function()
      ui.generate { output = out, font = 'Arial' }
    end).toThrow 'morrowind-ui: bundled font must be MysticCards, DejaVuLGCSansMono, or DemonicLetters'

    expect(function()
      ui.generate { output = out, primarySize = 16 }
    end).toThrow 'morrowind-ui: compiled oracle masks currently support primarySize 14 or 32'

    expect(function()
      ui.generate { output = out, secondarySize = 14 }
    end).toThrow 'morrowind-ui: compiled oracle masks currently support secondarySize 16'

    expect(function()
      ui.generate { output = out, primary = 'not a color' }
    end).toThrow 'magick: '

    local taken = plant(out, 'taken', 'a file')

    expect(function()
      ui.generate { output = taken }
    end).toThrow(taken .. ' exists and is not a directory')

    expect(support.files(out)).toEqual { 'taken' }
  end)
end)

suite.describe('generateAll', function()
  suite.it('lists the themes it makes', function()
    expect(ui.themes).toEqual(Themes)
  end)

  suite.it('makes every theme in a folder of its own, cleared first', function()
    local root = scratch('ui', 'all')
    local stale = plant(jess.fs.join(root, 'Rose', 'Textures'), 'stale.dds', 'left behind')
    local results = ui.generateAll(root, { seed = 5, font = 'Mystic Cards' })
    local expected = {}

    for index, theme in Themes do
      table.insert(expected, {
        output = jess.fs.join(root, theme.name, 'Textures'),
        files = 318,
        seed = 5 + index * 1000,
        font = 'MysticCards',
        primarySize = theme.primarySize or 32,
        secondarySize = 16,
      })
    end

    expect(results).toEqual(expected)
    expect(jess.fs.exists(stale)).toBe(false)
    pin('all', support.folder(root))

    for _, theme in Themes do
      pin(`all {theme.name}`, support.folder(jess.fs.join(root, theme.name, 'Textures')))
    end

    discard(root)
  end)
end)

suite.describe('shuffle', function()
  --- A tree of mods, each with a Textures folder: the one shuffled, and others with the files
  --- named.
  local function mods(name: string, others: { { string } }): (string, string)
    local root = scratch('shuffle', name)
    local own = jess.fs.join(root, 'own', 'Textures')

    jess.fs.createDir(own)

    for index, names in others do
      for _, file in names do
        plant(jess.fs.join(root, `other{index}`, 'Textures'), file, 'theirs')
      end
    end

    return root, own
  end

  suite.it('replaces each of its files with one taken from another mod', function()
    local root, own = mods('taken', { { 'first.dds', 'second.dds' } })

    plant(jess.fs.join(root, 'other1', 'Textures', 'nested'), 'third.dds', 'theirs')
    plant(own, 'menu.dds', 'ours')
    plant(own, 'cursor.dds', 'ours')
    jess.fs.createDir(jess.fs.join(own, 'folder'))

    expect(shuffle.shuffle { cwd = own, seed = 7 }).toEqual { directory = own, replaced = 2 }
    expect(support.file(jess.fs.join(own, 'menu.dds'))).toBe(support.digest 'theirs')
    expect(support.file(jess.fs.join(own, 'cursor.dds'))).toBe(support.digest 'theirs')
    expect(#support.files(jess.fs.join(root, 'other1'))).toBe(1)
    expect(#support.files(own)).toBe(2)
  end)

  suite.it('stops replacing when the other mods run out of files', function()
    local root, own = mods('exhausted', { { 'only.dds' } })

    plant(own, 'menu.dds', 'ours')
    plant(own, 'cursor.dds', 'ours')
    plant(own, 'frame.dds', 'ours')

    expect(shuffle.shuffle { cwd = own, seed = 1 }).toEqual { directory = own, replaced = 1 }
    expect(#support.files(jess.fs.join(root, 'other1'))).toBe(0)

    local taken = 0

    for _, name in support.files(own) do
      if support.file(jess.fs.join(own, name)) == support.digest 'theirs' then taken += 1 end
    end

    expect(taken).toBe(1)
  end)

  suite.it('takes from the one mod a seed chooses, whatever the seed', function()
    for _, seed in { 0, 1, 2147483647, 0x4655434B } do
      local root, own = mods(`seed{seed}`, { { 'first.dds' }, { 'second.dds' } })

      plant(own, 'menu.dds', 'ours')

      expect(shuffle.shuffle { cwd = own, seed = seed }).toEqual { directory = own, replaced = 1 }
      expect(#support.files(jess.fs.join(root, 'other1')) + #support.files(jess.fs.join(root, 'other2'))).toBe(1)
    end
  end)

  suite.it('refuses a folder with no mods beside it', function()
    local _, own = mods('alone', {})

    plant(own, 'menu.dds', 'ours')

    expect(function()
      shuffle.shuffle { cwd = own }
    end).toThrow 'no other directories with Textures subdirectory found'

    expect(support.file(jess.fs.join(own, 'menu.dds'))).toBe(support.digest 'ours')

    expect(function()
      shuffle.shuffle { cwd = '/' }
    end).toThrow 'cannot resolve ../../ from current directory'
  end)
end)

return suite
