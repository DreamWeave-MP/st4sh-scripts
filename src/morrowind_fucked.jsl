--!strict
--!native
--!optimize 2
-- Destructive port of generate_fucked.sh, isolated from the normal Morrowind generator.
local Shuffle = {}

--- The seed the files are chosen from, and the Textures folder shuffled: the one the process
--- stands in when none is given.
export type Options = { seed: number?, cwd: string? }

export type Result = { directory: string, replaced: number }

--- A Lehmer generator from a seed: `random(bound)` is in `1..bound`.
local function generator(seed: number?): (bound: number) -> number
  local state = (seed or 0x4655434B) % 2147483647

  if state <= 0 then state = 1 end

  return function(bound: number): number
    state = (state * 48271) % 2147483647

    return state % bound + 1
  end
end

--- Adds every file under a folder, however deep, to `found`.
local function collect(folder: string, found: { string })
  for _, name in jess.fs.list(folder) do
    local path = jess.fs.join(folder, name)

    if jess.fs.isDir(path) then
      collect(path, found)
    elseif jess.fs.isFile(path) then
      table.insert(found, path)
    end
  end
end

--- Replaces each file of a Textures folder with one chosen from the Textures folder of another
--- mod beside it, and removes the chosen file from where it was.
function Shuffle.shuffle(options: Options?): Result
  local settings: Options = options or {}
  local random = generator(settings.seed)
  local directory = settings.cwd or jess.fs.cwd()
  local parent = jess.fs.parent(directory)
  local mods = parent and jess.fs.parent(parent)

  if not mods then error('cannot resolve ../../ from current directory', 2) end

  local others: { string } = {}

  for _, name in jess.fs.list(mods) do
    local textures = jess.fs.join(mods, name, 'Textures')

    if jess.fs.isDir(textures) and textures ~= directory then table.insert(others, textures) end
  end

  if #others == 0 then error('no other directories with Textures subdirectory found', 2) end

  local replaced = 0

  for _, name in jess.fs.list(directory) do
    local target = jess.fs.join(directory, name)

    if not jess.fs.isFile(target) then continue end

    local files: { string } = {}

    collect(others[random(#others)], files)

    if #files == 0 then continue end

    local taken = files[random(#files)]

    jess.fs.copy(taken, target)
    jess.fs.remove(taken)
    replaced += 1
  end

  return { directory = directory, replaced = replaced }
end

return Shuffle
