-- Parser/dispatcher equivalents of the old loose *.luau adapters.
-- Call require('@st4sh/scripts.cli').run(command, args).
local atlas=require('@st4sh/scripts.atlas')
local h3=require('@st4sh/scripts.h3')
local mw=require('@st4sh/scripts.morrowind-ui')
local fucked=require('@st4sh/scripts.morrowind-fucked')
local cod3x=require('@st4sh/scripts.cod3x')
local variants=require('@st4sh/scripts.material-variants')
local M={}

local function need(args,i,flag)
    local v=args[i+1]
    if v==nil then error(flag..' needs a value',2) end
    return v,i+1
end

local function runAtlas(args)
    local o={mask=false,width=false,delete=false}; local i=1
    while i<=#args do local a=args[i]
        if a=='-i' or a=='--input' then o.input,i=need(args,i,a)
        elseif a=='-o' or a=='--output' then o.output,i=need(args,i,a)
        elseif a=='-r' or a=='--rows' then local v; v,i=need(args,i,a); o.rows=tonumber(v)
        elseif a=='-c' or a=='--cols' then local v; v,i=need(args,i,a); o.cols=tonumber(v)
        elseif a=='-m' or a=='--mask' then o.mask=true
        elseif a=='-w' or a=='--width' then o.width=true
        elseif a=='-d' or a=='--delete' then o.delete=true
        else error('unknown option: '..tostring(a),2) end
        i+=1
    end
    return atlas.generate(o)
end

local function runH3Header(args)
    local target=args[1] or 'all'; local crowbar=args[2] or 'crowbar.png'; local o={crowbar=crowbar}
    if target=='clean' then o.classified=false elseif target~='all' and target~='classified' then error('h3header [clean|classified|all] [crowbar.png]',2) end
    return h3.generateHeader(o)
end
local function runH3Logo(args)
    return h3.generateLogo{target=args[1] or 'all',crowbar=args[2] or 'crowbar.png',output=args[3] or 'out'}
end
local function runH3UI(args)
    local o={output='h3ui-textures',seed=3301}; local i=1
    while i<=#args do local a=args[i]
        if a=='-o' or a=='--output' then o.output,i=need(args,i,a)
        elseif a=='--material' then o.material,i=need(args,i,a)
        elseif a=='--material-crop' then local v; v,i=need(args,i,a); local x,y=string.match(v,'^(-?%d+),(-?%d+)$'); if not x then error('bad crop',2) end; o.cropX=tonumber(x); o.cropY=tonumber(y)
        elseif a=='--seed' then local v; v,i=need(args,i,a); o.seed=tonumber(v)
        elseif a=='-m' or a=='--magick' then local _; _,i=need(args,i,a)
        else error('unknown option: '..tostring(a),2) end
        i+=1
    end
    return h3.generateChromeSources(o)
end
local function runRecompose(args)
    local o={output='chrome-atlases'}; local i=1
    while i<=#args do local a=args[i]
        if a=='--h3ui' then o.h3ui,i=need(args,i,a)
        elseif a=='--morrowind' then o.morrowind,i=need(args,i,a)
        elseif a=='--openmw-textures' then o.openmw,i=need(args,i,a)
        elseif a=='-o' or a=='--output' then o.output,i=need(args,i,a)
        elseif a=='-m' or a=='--magick' then local _; _,i=need(args,i,a)
        else error('unknown option: '..tostring(a),2) end
        i+=1
    end
    return h3.recomposeChrome(o)
end
local function runMWMenu(args)
    local o={output='Textures'}; local i=1
    while i<=#args do local a=args[i]
        if a=='-p' or a=='--primary' then o.primary,i=need(args,i,a)
        elseif a=='-s' or a=='--secondary' then o.secondary,i=need(args,i,a)
        elseif a=='-t' or a=='--tertiary' then o.tertiary,i=need(args,i,a)
        elseif a=='-f' or a=='--font' then o.font,i=need(args,i,a)
        elseif a=='-pts' or a=='--primary-text-size' then local v; v,i=need(args,i,a); o.primarySize=tonumber(v)
        elseif a=='-sts' or a=='--secondary-text-size' then local v; v,i=need(args,i,a); o.secondarySize=tonumber(v)
        elseif a=='-pk' or a=='--primary-kerning' or a=='-sk' or a=='--secondary-kerning' then local v; v,i=need(args,i,a); if tonumber(v)~=0.75 then error('compiled font masks require kerning 0.75',2) end
        elseif a=='--seed' then local v; v,i=need(args,i,a); o.seed=tonumber(v)
        elseif a=='-o' or a=='--output' then o.output,i=need(args,i,a)
        else error('unknown parameter: '..tostring(a),2) end
        i+=1
    end
    return mw.generate(o)
end

local function runMaterialVariants(args)
    local o={stems={}}; local i=1
    while i<=#args do local a=args[i]
        if a=='--materials' then o.materials,i=need(args,i,a)
        elseif a=='--source-dir' then o.sourceDir,i=need(args,i,a)
        elseif a=='--install-dir' then o.installDir,i=need(args,i,a)
        elseif a=='--static-dir' then o.staticDir,i=need(args,i,a)
        elseif a=='--site-data' then o.siteData,i=need(args,i,a)
        elseif a=='--work-dir' then o.workDir,i=need(args,i,a)
        elseif a=='--random-crop' then o.randomCrop=true
        elseif a=='--material-crop' then local v; v,i=need(args,i,a); local x,y=string.match(v,'^(-?%d+),(-?%d+)$'); if not x then error('bad crop',2) end; o.materialCrop={tonumber(x),tonumber(y)}
        elseif a=='--seed' then local v; v,i=need(args,i,a); o.seed=tonumber(v)
        elseif a=='-m' or a=='--magick' then local _; _,i=need(args,i,a)
        elseif string.sub(a,1,1)=='-' then error('unknown option: '..tostring(a),2)
        else o.stems[#o.stems+1]=a end
        i+=1
    end
    return variants.build(o)
end

function M.run(command,args)
    args=args or {}
    if command=='atlas' then return runAtlas(args)
    elseif command=='h3header' then return runH3Header(args)
    elseif command=='h3logo' then return runH3Logo(args)
    elseif command=='h3ui' or command=='generate-h3ui-textures' then return runH3UI(args)
    elseif command=='recompose-chrome' then return runRecompose(args)
    elseif command=='morrowind-menu' then return runMWMenu(args)
    elseif command=='morrowind-all' then return mw.generateAll(args[1] or '.',{seed=tonumber(args[2] or '') or 0x4A455353})
    elseif command=='morrowind-fucked' then return fucked.shuffle{seed=tonumber(args[1] or '') or 0x4655434B}
    elseif command=='cod3x-hero' then return cod3x.generateHero{output=args[1] or '.'}
    elseif command=='cod3x-scope' then return cod3x.generateScope{output=args[1] or '.'}
    elseif command=='cod3x-mark' then return cod3x.generateMark{output=args[1] or '.'}
    elseif command=='cod3x-all' then return cod3x.generateAll{output=args[1] or '.'}
    elseif command=='material-variants' or command=='build-material-variants' then return runMaterialVariants(args)
    end
    error('unknown st4sh script command: '..tostring(command),2)
end
return M
