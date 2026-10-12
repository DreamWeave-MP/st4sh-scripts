--!native
--!optimize 2
-- Destructive port of generate_fucked.sh, isolated from the normal Morrowind generator.
local M={}
local function rng(seed)
    local state=(seed or 0x4655434B)%2147483647
    if state<=0 then state=1 end
    return function(n) state=(state*48271)%2147483647; return (state%n)+1 end
end
local function collect(dir,out)
    for _,name in jess.fs.list(dir) do
        local p=jess.fs.join(dir,name)
        if jess.fs.isDir(p) then collect(p,out) elseif jess.fs.isFile(p) then out[#out+1]=p end
    end
end
function M.shuffle(options)
    options=options or {}
    local random=rng(options.seed)
    local cwd=options.cwd or jess.fs.cwd()
    local parent=jess.fs.parent(cwd); local grand=parent and jess.fs.parent(parent)
    if not grand then error('cannot resolve ../../ from current directory',2) end
    local dirs={}
    for _,name in jess.fs.list(grand) do
        local d=jess.fs.join(grand,name,'Textures')
        if jess.fs.isDir(d) and d~=cwd then dirs[#dirs+1]=d end
    end
    if #dirs==0 then error('no other directories with Textures subdirectory found',2) end
    local replaced=0
    for _,name in jess.fs.list(cwd) do
        local dst=jess.fs.join(cwd,name)
        if jess.fs.isFile(dst) then
            local sourceDir=dirs[random(#dirs)]; local files={}; collect(sourceDir,files)
            if #files>0 then
                local src=files[random(#files)]
                jess.fs.copy(src,dst); jess.fs.remove(src); replaced+=1
            end
        end
    end
    return {directory=cwd,replaced=replaced}
end
return M
