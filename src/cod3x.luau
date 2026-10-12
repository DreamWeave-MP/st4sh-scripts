--!native
--!optimize 2
-- COD3X artwork generators ported from hero.sh, scope.sh, mark.sh, and generate.sh.
-- Text coverage is compiled from the supplied Oxanium WOFF2 through native ImageMagick.
local magick=require('@magick')
local masks=require('@st4sh/scripts.cod3x-masks')

local M={}

local BG='#101010'
local PANEL='#18151f'
local PURPLE='#55006b'
local VIOLET='#b48cff'
local TEXT='#f4f1f7'
local MUTED='#aeb4c0'
local GREEN='#7ee2a8'
local BLUE='#83c7ff'
local GOLD='#f2c66d'

local function ensureDir(path)
    if jess.fs.exists(path) then
        if not jess.fs.isDir(path) then error(path..' exists and is not a directory',2) end
    else
        jess.fs.createDir(path)
    end
end

local function overAlpha(out,name,color)
    out:overMask(masks.get(name),color)
    return out
end

local function write(path,img)
    magick.write(path,img)
    return path
end

function M.generateHero(options)
    options=options or {}
    local outdir=options.output or '.'
    ensureDir(outdir)
    local out=magick.new(1300,372,BG)
    out:strokeRect(10,10,1290,362,VIOLET,2)
    out:strokeRect(25,25,1275,347,VIOLET,1)
    out:line(54,78,1246,78,PURPLE,1)
    out:line(54,315,1246,315,PURPLE,1)
    overAlpha(out,'hero.title',TEXT)
    overAlpha(out,'hero.sub',VIOLET)
    overAlpha(out,'hero.tag',TEXT)
    overAlpha(out,'hero.meta',MUTED)
    -- @magick intentionally has no WebP codec yet; preserve the image pixels as PNG.
    local path=options.path or jess.fs.join(outdir,'nexusHeader.png')
    write(path,out)
    return {header=path,width=out.width,height=out.height}
end

function M.generateScope(options)
    options=options or {}
    local outdir=options.output or '.'
    ensureDir(outdir)
    local out=magick.new(1300,900,BG)
    out:strokeRect(20,20,1280,880,VIOLET,2)
    out:line(38,38,1262,38,VIOLET,1)
    out:line(38,862,1262,862,VIOLET,1)
    out:line(64,188,1236,188,PURPLE,1)
    out:line(64,832,1236,832,PURPLE,1)
    overAlpha(out,'scope.kicker',TEXT)
    overAlpha(out,'scope.title',VIOLET)
    overAlpha(out,'scope.sub',MUTED)

    local boxes={{64,270,608,410},{692,270,1236,410},{64,440,608,580},{692,440,1236,580},{64,610,608,750},{692,610,1236,750}}
    for _,b in boxes do out:roundRect(b[1],b[2],b[3],b[4],6,PURPLE,1) end
    local colors={GREEN,VIOLET,BLUE,GOLD,'#ff8f70',MUTED}
    for i=0,5 do
        overAlpha(out,'scope.card.title.'..i,colors[i+1])
        overAlpha(out,'scope.card.detail.'..i,TEXT)
    end
    local path=options.path or jess.fs.join(outdir,'scope.png')
    write(path,out)
    return {scope=path,width=out.width,height=out.height}
end

function M.generateMark(options)
    options=options or {}
    local outdir=options.output or '.'
    ensureDir(outdir)
    local icon=magick.new(512,512,BG)
    icon:strokeRect(24,24,488,488,VIOLET,4)
    icon:strokeRect(42,42,470,470,PURPLE,2)
    icon:line(72,104,440,104,PURPLE,2)
    icon:line(72,410,440,410,PURPLE,2)
    overAlpha(icon,'mark.icon.c3',VIOLET)
    overAlpha(icon,'mark.icon.tag',TEXT)
    overAlpha(icon,'mark.icon.name',MUTED)
    local iconPath=options.iconPath or jess.fs.join(outdir,'icon.png')
    write(iconPath,icon)

    local badge=magick.new(1600,1600,BG)
    badge:strokeRect(58,58,1542,1542,VIOLET,5)
    badge:strokeRect(88,88,1512,1512,PURPLE,2)
    badge:line(150,290,1450,290,PURPLE,2)
    badge:line(150,1343,1450,1343,PURPLE,2)
    overAlpha(badge,'mark.badge.c3',VIOLET)
    overAlpha(badge,'mark.badge.tag',TEXT)
    overAlpha(badge,'mark.badge.name',MUTED)
    overAlpha(badge,'mark.badge.desc',TEXT)
    overAlpha(badge,'mark.badge.meta',MUTED)
    local badgePath=options.badgePath or jess.fs.join(outdir,'badge.png')
    write(badgePath,badge)
    return {icon=iconPath,badge=badgePath}
end

function M.generateAll(options)
    options=options or {}
    local r={}
    r.hero=M.generateHero(options)
    r.scope=M.generateScope(options)
    r.mark=M.generateMark(options)
    return r
end

M.palette={BG=BG,PANEL=PANEL,PURPLE=PURPLE,VIOLET=VIOLET,TEXT=TEXT,MUTED=MUTED,GREEN=GREEN,BLUE=BLUE,GOLD=GOLD}
return M
