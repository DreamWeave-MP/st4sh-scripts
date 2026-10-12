--!native
--!optimize 2
-- Port of generate_menu.sh to Jess/Luau. No subprocesses; all raster work is @magick.

local magick = require("@magick")
local fontMasks = require("@st4sh/scripts.morrowind-font-masks")
local spiralMasks = require("@st4sh/scripts.morrowind-spiral-masks")
local oracleMasks = require("@st4sh/scripts.morrowind-oracle-masks")

local M = {}

local function canonicalFont(name)
    local k = string.lower(name or "MysticCards")
    if k == "mysticcards" or k == "mystic cards" then return "MysticCards" end
    if k == "dejavulgcsansmono" or k == "dejavulgcsansmono.ttf" or k == "dejavu lgc sans mono" then return "DejaVuLGCSansMono" end
    if k == "demonicletters" or k == "demonicletters.ttf" or k == "demonic letters" then return "DemonicLetters" end
    error("morrowind-ui: bundled font must be MysticCards, DejaVuLGCSansMono, or DemonicLetters", 2)
end

local function ensureDir(path)
    if jess.fs.exists(path) then
        if not jess.fs.isDir(path) then error(path .. " exists and is not a directory", 2) end
    else
        jess.fs.createDir(path)
    end
end

local function alphaMask(img)
    local b = buffer.create(img.width * img.height)
    for y=0,img.height-1 do for x=0,img.width-1 do local _,_,_,a=img:get(x,y); buffer.writeu8(b,y*img.width+x,a) end end
    return magick.mask(img.width,img.height,b)
end

local function maxMask(a,b)
    local out=buffer.create(a.width*a.height)
    for i=0,a.width*a.height-1 do buffer.writeu8(out,i,math.max(buffer.readu8(a.data,i),buffer.readu8(b.data,i))) end
    return magick.mask(a.width,a.height,out)
end

local function scaleMaskAlpha(mask, amount)
    local out=buffer.create(mask.width*mask.height)
    for i=0,mask.width*mask.height-1 do buffer.writeu8(out,i,math.floor(buffer.readu8(mask.data,i)*amount+0.5)) end
    return magick.mask(mask.width,mask.height,out)
end


local function applyAlpha(img, mask)
    assert(img.width==mask.width and img.height==mask.height, "alpha mask geometry mismatch")
    for y=0,img.height-1 do for x=0,img.width-1 do local r,g,b=img:get(x,y); img:set(x,y,r,g,b,buffer.readu8(mask.data,y*img.width+x)) end end
    return img
end

local function write(outDir,name,img)
    magick.writeDDS(jess.fs.join(outDir,name..".dds"),img)
end

local function textImage(font,kind,size,label,rotation,tile,secondary,strokeWidth,shadowRadius,shadowOpacity)
    local mask = fontMasks.get(font.."|"..kind.."|"..tostring(size).."|"..label.."|"..tostring(rotation or 0))
    if (strokeWidth or 0) <= 0 and (shadowOpacity or 0) <= 0 then return magick.paintMask(mask,tile) end
    local stroke = magick.dilateMask(mask,math.max(1,math.floor((strokeWidth or 1)+0.5)))
    local paintedStroke = magick.paintMask(stroke,secondary)
    local paintedFill = magick.paintMask(mask,tile)
    local out = magick.new(mask.width,mask.height)
    if (shadowOpacity or 0) > 0 then
        local combined=maxMask(mask,stroke)
        local blurred=magick.blurMask(combined,shadowRadius or 0)
        local shadow=magick.paintMask(scaleMaskAlpha(blurred,(shadowOpacity or 40)/100),secondary)
        out:over(shadow)
    end
    out:over(paintedStroke)
    out:over(paintedFill)
    if kind == "p" then
        local full = fontMasks.get(font.."|pfull|"..tostring(size).."|"..label.."|"..tostring(rotation or 0))
        applyAlpha(out, full)
    end
    return out
end

local function frameTextures(outDir,xLength,yLength,thickness,dark,light,name,cornerSuffix)
    local w=xLength+thickness*2; local h=yLength+thickness*2
    local solid=magick.new(w,h); solid:rect(0,0,w-1,h-1,dark); solid:rect(thickness,thickness,xLength+thickness-1,yLength+thickness-1,light)
    write(outDir,name.."_solid",solid)
    local hollow=solid:clone()
    for y=thickness*2,yLength-1 do for x=thickness*2,xLength-1 do local r,g,b= hollow:get(x,y); hollow:set(x,y,r,g,b,0) end end
    write(outDir,name.."_hollow",hollow)
    local center=solid:crop(xLength-thickness*2,yLength-thickness*2,thickness*2,thickness*2)
    write(outDir,name.."_center",center)
    local st=thickness*2; local innerX=xLength-st; local innerY=yLength-st
    local leftSide=hollow:crop(st,h,0,0); local rightSide=hollow:crop(st,h,xLength,0)
    write(outDir,name.."_left_side",leftSide); write(outDir,name.."_right_side",rightSide)
    write(outDir,name.."_left",leftSide:crop(st,innerY,0,st)); write(outDir,name.."_right",rightSide:crop(st,innerY,0,st))
    local topSide=hollow:crop(w,st,0,0); local bottomSide=hollow:crop(w,st,0,yLength)
    write(outDir,name.."_top_side",topSide); write(outDir,name.."_bottom_side",bottomSide)
    write(outDir,name.."_top",topSide:crop(innerX,st,st,0)); write(outDir,name.."_bottom",bottomSide:crop(innerX,st,st,0))
    local suffix=cornerSuffix or "_corner"
    write(outDir,name.."_top_left"..suffix,topSide:crop(st,st,0,0)); write(outDir,name.."_top_right"..suffix,topSide:crop(st,st,xLength,0))
    write(outDir,name.."_bottom_left"..suffix,bottomSide:crop(st,st,0,0)); write(outDir,name.."_bottom_right"..suffix,bottomSide:crop(st,st,xLength,0))
end

local function radialTile(tile,size)
    local w,h=size,size; local out=magick.new(w,h); local cx=(w-1)/2; local cy=(h-1)/2; local maxd=math.sqrt(cx*cx+cy*cy)
    for y=0,h-1 do for x=0,w-1 do local r,g,b,a=tile:get(x%tile.width,y%tile.height); local dx=x-cx; local dy=y-cy; local alpha=math.max(0,1-math.sqrt(dx*dx+dy*dy)/maxd); out:set(x,y,r,g,b,a*alpha) end end
    return out
end

local function iconSet(outDir,base,active,highlight,secondary)
    local equip=magick.new(39,39); equip:rect(0,0,38,38,highlight); equip:rect(1,1,37,37,active)
    -- DstOut a 14px radius circle centered at (19,19).
    for y=0,38 do for x=0,38 do local dx=(x-19); local dy=(y-19); if dx*dx+dy*dy <= 14*14 then local r,g,b=equip:get(x,y); equip:set(x,y,r,g,b,0) end end end
    applyAlpha(equip,oracleMasks.get("equip_frame_base"))
    write(outDir,"equip_frame_base",equip)
    local menuEquip=magick.new(64,64); menuEquip:over(equip,2,2); write(outDir,"menu_icon_equip",menuEquip)

    local enchantBase=radialTile(highlight,43); applyAlpha(enchantBase,oracleMasks.get("enchant_frame_base")); write(outDir,"enchant_frame_base",enchantBase)
    local spirals={
        {"enchant_frame_spiral","menu_icon_magic_spiral","menu_icon_magic_equip_spiral"},
        {"enchant_frame_spiral_large","menu_icon_magic_spiral_large","menu_icon_magic_equip_spiral_large"},
    }
    local base64=magick.new(64,64); base64:over(enchantBase,0,0); write(outDir,"menu_icon_magic",base64)
    local equipBase=magick.new(64,64); local eb=enchantBase:resize(43,43,true):crop(39,39,2,2); local small=magick.new(39,39); small:over(eb); small:over(equip); equipBase:over(small,2,2); write(outDir,"menu_icon_magic_equip",equipBase)
    for _,row in spirals do
        local mask=spiralMasks.get(row[1]); local spiral=magick.paintMask(mask,secondary); write(outDir,row[1],spiral)
        local icon=magick.new(64,64); icon:over(spiral,0,0); write(outDir,row[2],icon)
        local e=spiral:resize(43,43,true):crop(39,39,2,2); local combo=magick.new(39,39); combo:over(e); combo:over(equip); local big=magick.new(64,64); big:over(combo,2,2); applyAlpha(big,oracleMasks.get(row[3])); write(outDir,row[3],big)
    end
end

local function scrollbars(outDir,base,active,highlight,seed)
    local x=(seed*37)% (512-16); local y=(seed*91)% (512-32)
    local h=active:crop(16,32,x,y); write(outDir,"omw_menu_scroll_center_h",h); write(outDir,"omw_menu_scroll_center_v",h:rotate90(true))
    local up=magick.new(16,16); up:polygon({{0,14},{14,14},{7,1}},highlight); up:polygon({{1,13},{13,13},{7,2}},active); applyAlpha(up,oracleMasks.get("omw_menu_scroll_up")); write(outDir,"omw_menu_scroll_up",up)
    local left=up:rotate90(false); applyAlpha(left,oracleMasks.get("omw_menu_scroll_left")); write(outDir,"omw_menu_scroll_left",left); local right=up:rotate90(true); applyAlpha(right,oracleMasks.get("omw_menu_scroll_right")); write(outDir,"omw_menu_scroll_right",right)
    local down=magick.new(16,16); down:polygon({{0,1},{14,1},{7,14}},highlight); down:polygon({{1,2},{13,2},{7,13}},active); applyAlpha(down,oracleMasks.get("omw_menu_scroll_down")); write(outDir,"omw_menu_scroll_down",down)
end

local function cursor(outDir,base,active)
    -- The oracle supplies IM's exact antialiased rotate/emboss silhouette; theme color stays live.
    local mask=oracleMasks.get("tx_cursor")
    local out=magick.paintMask(mask,active)
    write(outDir,"tx_cursor",out)
end

function M.generate(options)
    options=options or {}
    local outDir=options.output or "Textures"
    ensureDir(outDir)
    local primary=magick.color(options.primary or "#b20047")
    local secondary=magick.color(options.secondary or "#00ff99")
    local tertiary=magick.color(options.tertiary or "#ff4d94")
    local font=canonicalFont(options.font or "MysticCards")
    local primarySize=options.primarySize or 32
    local secondarySize=options.secondarySize or 16
    if primarySize ~= 14 and primarySize ~= 32 then error("morrowind-ui: compiled oracle masks currently support primarySize 14 or 32",2) end
    if secondarySize ~= 16 then error("morrowind-ui: compiled oracle masks currently support secondarySize 16",2) end
    local seed=math.floor(options.seed or 0x4A455353)

    local base=magick.noise(512,512,primary,seed+1,0.25)
    local highlight=magick.noise(512,512,secondary,seed+2,0.25)
    local active=magick.noise(512,512,tertiary,seed+3,0.25)
    write(outDir,"noise_base",base); write(outDir,"noise_highlight",highlight); write(outDir,"noise_active",active)

    local esc={"Credits","Exit","Load","New","Options","Save","Return","Papa_Bless"}
    for _,label in esc do
        for _,state in {{"",0,base},{"_pressed",20,active},{"_over",20,base}} do
            local img=textImage(font,"p",primarySize,label,state[2],state[3],secondary,1,5,40)
            local name="menu_"..label..state[1]
            if label=="Save" then name="menu_savegame"..state[1] elseif label=="New" then name="menu_newgame"..state[1] elseif label=="Load" then name="menu_loadgame"..state[1] elseif label=="Exit" then name="menu_exitgame"..state[1] end
            write(outDir,name,img)
        end
    end

    local journal={"Cancel","Close","Journal","Next","Options","Prev","Quests","All","Active","Topics","Take"}
    for _,label in journal do
        for _,state in {{"_idle",active},{"_pressed",base},{"_over",highlight}} do
            local img=textImage(font,"j",secondarySize,label,0,state[2],secondary,0,0,0)
            local outLabel=label
            if label=="All" then outLabel="quests_all" elseif label=="Active" then outLabel="quests_active" end
            write(outDir,"tx_menubook_"..outLabel..state[1],img)
        end
    end

    scrollbars(outDir,base,active,highlight,seed)
    iconSet(outDir,base,active,highlight,secondary)

    frameTextures(outDir,512,512,1,active,highlight,"menu_thin_border")
    frameTextures(outDir,512,512,2,active,highlight,"menu_thick_border")
    frameTextures(outDir,256,16,1,highlight,active,"menu_head_block")
    -- Match the original's odd rename of center -> middle.
    jess.fs.copy(jess.fs.join(outDir,"menu_head_block_center.dds"),jess.fs.join(outDir,"menu_head_block_middle.dds"))
    jess.fs.remove(jess.fs.join(outDir,"menu_head_block_center.dds"))
    frameTextures(outDir,128,16,4,active,highlight,"menu_button_frame")
    frameTextures(outDir,12,12,2,highlight,active,"menu_rightbuttondown","")
    frameTextures(outDir,12,12,2,active,highlight,"menu_rightbuttonup","")

    frameTextures(outDir,120,120,4,active,highlight,"extra_frame_128_thick")
    frameTextures(outDir,124,124,2,active,highlight,"extra_frame_128_thin")
    frameTextures(outDir,64,64,4,active,highlight,"extra_frame_72_thick")
    frameTextures(outDir,68,68,2,active,highlight,"extra_frame_72_thin")
    frameTextures(outDir,24,24,4,active,highlight,"extra_frame_36_thick")
    frameTextures(outDir,32,32,2,active,highlight,"extra_frame_36_thin")
    frameTextures(outDir,28,28,2,active,highlight,"extra_frame_32_thin")
    frameTextures(outDir,24,24,4,active,highlight,"extra_frame_32_thick")
    frameTextures(outDir,16,16,1,active,highlight,"extra_frame_18_thin")
    frameTextures(outDir,14,14,2,active,highlight,"extra_frame_18_thick")
    cursor(outDir,base,active)

    return { output=outDir, files=#jess.fs.list(outDir), seed=seed, font=font, primarySize=primarySize, secondarySize=secondarySize }
end

M.themes = {
    {name="ArcaneEnergy", primary="AA00FF", tertiary="5500AA", secondary="E040FB"},
    {name="MysticOcean", primary="0074d9", secondary="001f3f", tertiary="7fdbff"},
    {name="momw", primary="222", secondary="444", tertiary="333"},
    {name="Prim", primary="f1ecf6", secondary="7a49a5", tertiary="d7c8e4"},
    {name="PickleRick", primary="a3ffb4", tertiary="4974a5", secondary="304c36"},
    {name="White-Rose", primary="843c54", tertiary="5c2a3a", secondary="271219"},
    {name="Beige", primary="ffa500", tertiary="4974a5", secondary="fff6e5"},
    {name="America", primary="fff", tertiary="f00", secondary="00f"},
    {name="Rose"},
    {name="Royale", primary="000", tertiary="180e21", secondary="492b63"},
    {name="Blood-Raven", primary="ff0000", tertiary="190000", secondary="000000"},
    {name="Mono", primary="000", secondary="333", tertiary="fff"},
    {name="VeryDark", primary="fff", secondary="333", tertiary="111"},
    {name="Cobalt", primary="000000", secondary="0066ff", tertiary="002866", primarySize=14},
    {name="IndustrialSteel", tertiary="3d3d3d", secondary="7f8c8d", primary="bdc3c7"},
}

function M.generateAll(root, options)
    root=root or "."; options=options or {}; ensureDir(root)
    local results={}
    for i,theme in M.themes do
        local out=jess.fs.join(root,theme.name,"Textures"); ensureDir(jess.fs.join(root,theme.name))
        if jess.fs.exists(out) then
            for _,name in jess.fs.list(out) do jess.fs.remove(jess.fs.join(out,name)) end
        else ensureDir(out) end
        local cfg={output=out,primary=theme.primary,secondary=theme.secondary,tertiary=theme.tertiary,primarySize=theme.primarySize,font=options.font,seed=(options.seed or 0x4A455353)+i*1000}
        results[#results+1]=M.generate(cfg)
    end
    return results
end

return M
