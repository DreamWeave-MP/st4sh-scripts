--!strict
--!native
-- The command line of the old loose scripts, pinned: what each command makes of its arguments,
-- held to the files and the answer of the generator behind it, and what it refuses. Commands
-- that write where the process happens to stand (`h3header`, `morrowind-fucked`) are held only
-- to what they refuse before they write.
local cli = require '@st4sh/scripts.cli'
local goldens = require './goldens'
local magick = require '@magick'
local scripts = require '@st4sh/scripts'
local support = require './support'
local test = require '@jess/test'
local ui = require '@st4sh/scripts.morrowind-ui'
local variants = require '@st4sh/scripts.material-variants'

local expect = test.expect
local suite = test.new()
local pin, settle = support.goldens(goldens.cli)
local scratch, join = support.scratch, jess.fs.join

--- A picture of noise written as a PNG, and its path.
local function photo(folder: string, name: string, width: number, height: number, seed: number): string
  return magick.write(join(folder, name), support.picture(width, height, seed))
end

--- Removes every file under a folder.
local function discard(folder: string)
  for _, path in support.files(folder) do
    jess.fs.remove(join(folder, path))
  end
end

suite.afterEach(settle)

suite.describe('the toolbox', function()
  suite.it('gathers the modules under one frozen table', function()
    expect(table.isfrozen(scripts)).toBe(true)
    expect(scripts.atlas).toBe(require '@st4sh/scripts.atlas')
    expect(scripts.morrowind).toBe(ui)
    expect(scripts.morrowindFucked).toBe(require '@st4sh/scripts.morrowind-fucked')
    expect(scripts.h3).toBe(require '@st4sh/scripts.h3')
    expect(scripts.cod3x).toBe(require '@st4sh/scripts.cod3x')
    expect(scripts.materialVariants).toBe(variants)
    expect(scripts.cli).toBe(cli)
  end)

  suite.it('refuses a command it does not have', function()
    expect(function()
      cli.run('paint', {})
    end).toThrow 'unknown st4sh script command: paint'

    expect(function()
      ((cli.run :: unknown) :: (command: unknown) -> unknown)(nil)
    end).toThrow 'unknown st4sh script command: nil'
  end)
end)

suite.describe('atlas', function()
  suite.it('reads its switches, short and long', function()
    local out = scratch('cli', 'atlas')
    local input = photo(out, 'source.png', 24, 16, 55)
    local short, long = join(out, 'short.dds'), join(out, 'long.dds')

    expect(cli.run('atlas', { '-i', input, '-o', short, '-r', '2', '-c', '3', '-m', '-w', '-d' })).toEqual {
      output = short,
      width = 72,
      height = 32,
      rows = 2,
      cols = 3,
      tiles = 6,
    }

    expect(cli.run('atlas', { '--input', input, '--output', long, '--rows', '3', '--cols', '2', '--mask' })).toEqual {
      output = long,
      width = 48,
      height = 48,
      rows = 3,
      cols = 2,
      tiles = 6,
    }

    pin('atlas short', support.file(short))
    pin('atlas long', support.file(long))
    cli.run('atlas', { '--mask', '--width', '-i', input, '-o', short, '-r', '2', '-c', '3' })
    pin('atlas width', support.file(short))
    cli.run('atlas', { '--delete', '-i', input, '-o', short, '-r', '2', '-c', '3' })
    pin('atlas delete without mask', support.file(short))
  end)

  suite.it('refuses a switch it does not have, and one without its value', function()
    expect(function()
      cli.run('atlas', { '--tiles', '4' })
    end).toThrow 'unknown option: --tiles'

    expect(function()
      cli.run('atlas', { '-i', 'source.png', '-o' })
    end).toThrow '-o needs a value'

    expect(function()
      cli.run('atlas', { '--rows' })
    end).toThrow '--rows needs a value'

    expect(function()
      cli.run 'atlas'
    end).toThrow 'atlas: input required'

    expect(function()
      cli.run('atlas', { '-i', 'source.png', '-o', 'atlas.dds', '-r', 'two', '-c', '3' })
    end).toThrow 'atlas: rows required'
  end)
end)

suite.describe('h3', function()
  suite.it('refuses a header target it does not have', function()
    expect(function()
      cli.run('h3header', { 'poster' })
    end).toThrow 'h3header [clean|classified|all] [crowbar.png]'
  end)

  suite.it('makes the logo target asked for, from a crowbar, into a folder', function()
    local out = scratch('cli', 'logo')
    local crowbar = photo(out, 'crowbar.png', 90, 140, 21)

    expect(cli.run('h3logo', { 'icon', crowbar, join(out, 'made') })).toEqual {
      icon = join(out, 'made', 'h3_icon_v6.png'),
    }

    pin('logo icon', support.file(join(out, 'made', 'h3_icon_v6.png')))
  end)

  suite.it('makes the chrome sources of a material, and recomposes them', function()
    local out = scratch('cli', 'chrome')
    local material = photo(out, 'material.png', 100, 80, 33)
    local sources = join(out, 'sources', 'Textures', 'h3ui')

    local made = cli.run('h3ui', {
      '--material',
      material,
      '--material-crop',
      '20,0',
      '--seed',
      '5',
      '-m',
      'convert',
      '-o',
      join(out, 'sources'),
    })

    expect(made).toEqual { output = sources, cropX = 20, cropY = 0, files = 12 }
    pin('chrome sources cropped', support.folder(sources))

    local recomposed = cli.run('recompose-chrome', {
      '--h3ui',
      sources,
      '--magick',
      'convert',
      '--output',
      join(out, 'atlases'),
    })

    expect(recomposed).toEqual {
      manifest = join(out, 'atlases', 'h3ui_chrome_manifest.lua'),
      output = join(out, 'atlases', 'Textures', 'h3ui'),
      h3ui = join(out, 'atlases', 'Textures', 'h3ui', 'h3ui_chrome.dds'),
    }

    pin('recomposed', support.folder(join(out, 'atlases')))
  end)

  suite.it('refuses chrome switches it does not have, a bad crop and no material', function()
    for _, command in { 'h3ui', 'generate-h3ui-textures' } do
      expect(function()
        cli.run(command, { '--material-crop', '20' })
      end).toThrow 'bad crop'

      expect(function()
        cli.run(command, { '--material-crop', '2.5,0' })
      end).toThrow 'bad crop'

      expect(function()
        cli.run(command, { '--crop', '20,0' })
      end).toThrow 'unknown option: --crop'

      expect(function()
        cli.run(command, { '--seed' })
      end).toThrow '--seed needs a value'

      expect(function()
        cli.run(command, { '--seed', '5', '-m', 'convert' })
      end).toThrow 'h3-tools: --material path required'
    end

    expect(function()
      cli.run('recompose-chrome', { '--theme', 'h3ui' })
    end).toThrow 'unknown option: --theme'

    expect(function()
      cli.run('recompose-chrome', { '-m', 'convert' })
    end).toThrow 'h3-tools: one of h3ui or morrowind is required'

    expect(function()
      cli.run('recompose-chrome', { '--openmw-textures', 'nowhere', '-o', scratch('cli', 'refused') })
    end).toThrow 'h3-tools: one of h3ui or morrowind is required'
  end)
end)

suite.describe('morrowind', function()
  suite.it('makes a menu theme from its switches', function()
    local out = scratch('cli', 'menu')

    local result = cli.run('morrowind-menu', {
      '-p',
      '#102030',
      '--secondary',
      '0f8',
      '-t',
      'c86432ff',
      '--font',
      'DejaVu LGC Sans Mono',
      '-pts',
      '14',
      '--secondary-text-size',
      '16',
      '-pk',
      '0.75',
      '--secondary-kerning',
      '0.750',
      '--seed',
      '77',
      '-o',
      out,
    })

    expect(result).toEqual {
      output = out,
      files = 318,
      seed = 77,
      font = 'DejaVuLGCSansMono',
      primarySize = 14,
      secondarySize = 16,
    }

    pin('menu', support.folder(out))
    discard(out)
  end)

  suite.it('refuses menu switches it does not have, and a kerning the masks were not made with', function()
    expect(function()
      cli.run('morrowind-menu', { '--kerning', '0.75' })
    end).toThrow 'unknown parameter: --kerning'

    for _, switch in { '-pk', '--primary-kerning', '-sk', '--secondary-kerning' } do
      expect(function()
        cli.run('morrowind-menu', { switch, '1' })
      end).toThrow 'compiled font masks require kerning 0.75'

      expect(function()
        cli.run('morrowind-menu', { switch })
      end).toThrow(switch .. ' needs a value')
    end

    expect(function()
      cli.run('morrowind-menu', { '-f', 'Arial', '-o', scratch('cli', 'menu-refused') })
    end).toThrow 'morrowind-ui: bundled font must be MysticCards, DejaVuLGCSansMono, or DemonicLetters'

    expect(function()
      cli.run('morrowind-menu', { '--primary-text-size', '20', '-o', scratch('cli', 'menu-refused') })
    end).toThrow 'morrowind-ui: compiled oracle masks currently support primarySize 14 or 32'

    expect(function()
      cli.run('morrowind-menu', { '-sts', '12', '-o', scratch('cli', 'menu-refused') })
    end).toThrow 'morrowind-ui: compiled oracle masks currently support secondarySize 16'
  end)

  suite.it('makes every theme under a root, from a seed', function()
    local root = scratch('cli', 'all')
    local results = cli.run('morrowind-all', { root, '5' }) :: { ui.Result }

    expect(#results).toBe(15)
    expect(results[1]).toEqual {
      output = join(root, 'ArcaneEnergy', 'Textures'),
      files = 318,
      seed = 1005,
      font = 'MysticCards',
      primarySize = 32,
      secondarySize = 16,
    }

    expect(results[14].primarySize).toBe(14)
    expect(results[15].seed).toBe(15005)
    pin('all', support.folder(root))
    discard(root)
  end)
end)

suite.describe('cod3x and material variants', function()
  suite.it('makes each piece of COD3X into a folder', function()
    local out = scratch('cli', 'cod3x')

    expect(cli.run('cod3x-hero', { join(out, 'hero') })).toEqual {
      header = join(out, 'hero', 'nexusHeader.png'),
      width = 1300,
      height = 372,
    }

    expect(cli.run('cod3x-scope', { join(out, 'scope') })).toEqual {
      scope = join(out, 'scope', 'scope.png'),
      width = 1300,
      height = 900,
    }

    expect(cli.run('cod3x-mark', { join(out, 'mark') })).toEqual {
      icon = join(out, 'mark', 'icon.png'),
      badge = join(out, 'mark', 'badge.png'),
    }

    expect(cli.run('cod3x-all', { join(out, 'all') })).toEqual {
      hero = { header = join(out, 'all', 'nexusHeader.png'), width = 1300, height = 372 },
      scope = { scope = join(out, 'all', 'scope.png'), width = 1300, height = 900 },
      mark = { icon = join(out, 'all', 'icon.png'), badge = join(out, 'all', 'badge.png') },
    }

    pin('cod3x', support.folder(out))
  end)

  suite.it('builds the material variants its switches name', function()
    local folder = scratch('cli', 'variants')
    local install, static, work = join(folder, 'install'), join(folder, 'static'), join(folder, 'work')
    local siteData = join(folder, 'materials.json')

    local catalog = 'stem\tfamily\tname\tphoto\tcropX\tcropY\turl\tauthor\tlicense\n'
      .. 'slate\tStone\tSlate\tslate.png\t3\t0\thttps://example.test/slate\tA. Mason\tCC0\n'
      .. 'oak\tWood\tOak\toak.png\t0\t9\thttps://example.test/oak\tJ. Joiner\tCC-BY\n'

    photo(folder, 'slate.png', 100, 80, 71)
    photo(folder, 'oak.png', 70, 90, 72)
    jess.fs.write(join(folder, 'materials.tsv'), catalog)

    local result = cli.run('material-variants', {
      '--materials',
      join(folder, 'materials.tsv'),
      '--source-dir',
      folder,
      '--install-dir',
      install,
      '--static-dir',
      static,
      '--site-data',
      siteData,
      '--work-dir',
      work,
      '--material-crop',
      '0,7',
      '--seed',
      '11',
      '-m',
      'convert',
      'oak',
    })

    expect(result).toEqual {
      count = 1,
      built = { { stem = 'oak', cropX = 0, cropY = 7, output = join(install, 'chrome', 'oak.dds') } },
    }

    pin('variants oak', support.file(join(install, 'chrome', 'oak.dds')))
    pin('variants oak preview', support.file(join(static, 'oak.png')))
    pin('variants site data', support.file(siteData))
    pin('variants work', support.folder(work))

    local random = cli.run('build-material-variants', {
      'slate',
      '--materials',
      join(folder, 'materials.tsv'),
      '--source-dir',
      folder,
      '--install-dir',
      install,
      '--random-crop',
    }) :: variants.Result

    expect(random.count).toBe(1)
    pin('variants random crop', `{random.built[1].cropX},{random.built[1].cropY}`)
    pin('variants random slate', support.file(join(install, 'chrome', 'slate.dds')))
  end)

  suite.it('refuses variant switches it does not have, a bad crop and no catalog', function()
    for _, command in { 'material-variants', 'build-material-variants' } do
      expect(function()
        cli.run(command, { '--stems', 'oak' })
      end).toThrow 'unknown option: --stems'

      expect(function()
        cli.run(command, { '--material-crop', '0;7' })
      end).toThrow 'bad crop'

      expect(function()
        cli.run(command, { 'oak', '--work-dir' })
      end).toThrow '--work-dir needs a value'

      expect(function()
        cli.run(command, { 'oak', '--random-crop' })
      end).toThrow 'material variants: materials TSV required'
    end
  end)
end)

return suite
