--!native
--!optimize 2
local magick=require('@magick')
local masks=require('@st4sh/scripts.h3-masks')

local M={}

local function ensureDir(path)
    if jess.fs.exists(path) then
        if not jess.fs.isDir(path) then error(path..' exists and is not a directory',2) end
    else jess.fs.createDir(path) end
end

local function alphaImage(mask,color)
    return magick.maskToImage(mask,color)
end

local function clipAlpha(img,maskImg)
    return img:copyAlpha(maskImg,'dstin')
end

local function polygonImage(w,h,points,color)
    local out=magick.new(w,h)
    out:polygon(points,color)
    return out
end

local function drawBaseHeader()
    local BG='#090909'; local IVORY='#e8e1d2'; local w,h=1300,372
    local out=magick.new(w,h,BG)
    out:strokeRect(10,10,1290,362,IVORY,2)
    out:strokeRect(25,25,1275,347,IVORY,1)
    out:line(54,91,1246,91,IVORY,1)
    out:line(54,314,1246,314,IVORY,1)
    return out
end

local function headerClean(crowbarPath)
    local W,H=1300,372
    local IVORY='#e8e1d2'; local PAPER='#cfc6bc'
    local out=drawBaseHeader()
    out:over(alphaImage(masks.get('header.left_text'),IVORY))
    out:polygonOver({{860,100},{1235,104},{1241,294},{872,298}},PAPER)
    out:polygonOver({{880,119},{1216,122},{1221,275},{890,278}},'#050505')
    local panelMask=polygonImage(W,H,{{880,119},{1216,122},{1221,275},{890,278}},'#ffffffff')
    local h3=alphaImage(masks.get('header.h3_full'),IVORY)
    clipAlpha(h3,panelMask)
    out:over(h3)

    local crow=magick.read(crowbarPath):resizeFit(205,255):rotate(-5)
    crow=magick.shadowed(crow,30,3,3,4)
    out:over(crow,1015,70)

    local frontMask=magick.new(W,H); frontMask:rect(968,94,1016,198,'#ffffffff')
    local front=h3:clone(); clipAlpha(front,frontMask)
    out:over(front)
    return out
end

local function makeDust(w,h,thresholdPct,alphaPct,ivory,seed)
    local d=magick.randomNoise(w,h,seed or 1):threshold(thresholdPct/100)
    d:transparent('#000000'):opaque('#ffffff',ivory):setAlpha(alphaPct/100)
    return d
end

function M.generateHeader(options)
    options=options or {}
    local crowbar=assert(options.crowbar,'h3-tools: crowbar path required')
    local clean=headerClean(crowbar)
    local cleanPath=options.cleanOutput or 'nexusHeaderClean.png'
    magick.write(cleanPath,clean)
    if options.classified==false then return {clean=cleanPath} end
    local out=clean:clone()
    local approved=alphaImage(masks.get('header.approved'),'#5c2a75')
    out:over(approved,57,out.height-approved.height-66)
    out:over(makeDust(out.width,out.height,86,6,'#e8e1d2',options.seed or 3301),0,0)
    out=magick.addGaussianNoise(out,(options.seed or 3301)+1,0.012)
    local classified=options.output or 'nexusHeader.png'
    magick.write(classified,out)
    return {clean=cleanPath,classified=classified,width=out.width,height=out.height}
end

local function baseBadge()
    local out=magick.new(1600,1600,'#0a0a0a'); local ivory='#e8e1d2'
    out:strokeRect(48,48,1552,1552,ivory,4)
    out:strokeRect(78,78,1522,1522,ivory,2)
    out:line(120,195,1480,195,ivory,2)
    out:line(120,1410,1480,1410,ivory,2)
    out:strokeRect(210,265,1390,1170,ivory,2)
    return out
end

local function logoPanel(w,h)
    local back=polygonImage(w,h,{{230,275},{1335,272},{1352,1145},{248,1158}},'#cfc6bc')
    local fill=polygonImage(w,h,{{265,305},{1305,300},{1318,1112},{282,1124}},'#050505')
    local mask=polygonImage(w,h,{{265,305},{1305,300},{1318,1112},{282,1124}},'#ffffffff')
    return back,fill,mask
end

local function logoClean(crowbarPath)
    local W,H=1600,1600; local ivory='#e8e1d2'
    local out=baseBadge()
    out:over(alphaImage(masks.get('logo.text'),ivory))
    local back,fill,panelMask=logoPanel(W,H); out:over(back); out:over(fill)
    local h3=alphaImage(masks.get('logo.h3_full'),ivory); clipAlpha(h3,panelMask); out:over(h3)
    local frontMask=magick.new(W,H)
    frontMask:rect(400,470,640,955,'#ffffffff'):rect(900,470,1105,625,'#ffffffff'):rect(835,770,1115,1010,'#ffffffff')
    local front=h3:clone(); clipAlpha(front,frontMask)
    local crow=magick.read(crowbarPath):resizeFit(1080,1080):rotate(-4)
    crow=magick.shadowed(crow,40,5,5,7)
    out:over(crow,250,210)
    out:over(front)
    return out
end

local function logoIcon(crowbarPath)
    local W,H=512,512; local ivory='#e8e1d2'
    local out=magick.new(W,H)
    out:rect(18,18,494,494,'#0a0a0a'); out:strokeRect(18,18,494,494,ivory,3); out:strokeRect(30,30,482,482,ivory,2)
    out:polygonOver({{70,80},{430,78},{436,420},{76,430}},'#cfc6bc')
    out:polygonOver({{92,98},{406,94},{412,402},{98,412}},'#050505')
    local panelMask=polygonImage(W,H,{{92,98},{406,94},{412,402},{98,412}},'#ffffffff')
    local h3=alphaImage(masks.get('logo.icon_h3_full'),ivory); clipAlpha(h3,panelMask); out:over(h3)
    local frontMask=magick.new(W,H); frontMask:rect(125,125,210,310,'#ffffffff'):rect(285,128,378,184,'#ffffffff'):rect(255,270,404,365,'#ffffffff')
    local front=h3:clone(); clipAlpha(front,frontMask)
    local crow=magick.read(crowbarPath):resizeFit(345,345):rotate(-4)
    out:over(crow,78,58); out:over(front)
    return out
end

function M.generateLogo(options)
    options=options or {}; local crowbar=assert(options.crowbar,'h3-tools: crowbar path required'); local outDir=options.output or 'out'; ensureDir(outDir)
    local target=options.target or 'all'; local result={}
    if target=='clean' or target=='classified' or target=='all' then
        local clean=logoClean(crowbar); local p=jess.fs.join(outDir,'h3_badge_clean_v6.png'); magick.write(p,clean); result.clean=p
        if target=='classified' or target=='all' then
            local c=clean:clone(); local stamp=alphaImage(masks.get('logo.stamp'),'#8f1d2c')
            local sx=math.floor((c.width-stamp.width)/2); local sy=math.floor((c.height-stamp.height)/2)-5; c:over(stamp,sx,sy)
            local note=alphaImage(masks.get('logo.purple_note'),'#5c2a75'); c:over(note,100,c.height-note.height-115)
            c:over(makeDust(c.width,c.height,82,10,'#e8e1d2',options.seed or 3301),0,0)
            c=magick.addGaussianNoise(c,(options.seed or 3301)+1,0.02)
            local cp=jess.fs.join(outDir,'h3_badge_classified_v6.png'); magick.write(cp,c); result.classified=cp
        end
    end
    if target=='icon' or target=='all' then local icon=logoIcon(crowbar); local p=jess.fs.join(outDir,'h3_icon_v6.png'); magick.write(p,icon); result.icon=p end
    return result
end

local function toneMaterial(material,low,high)
    local slope=(high-low)/100; local intercept=low/100
    return material:clone():polynomial(slope,intercept):grayscale()
end

local function shadeRaised(file,width,height,margin,strength)
    strength=strength or 100; local inner=margin-1; local bottom=height-1; local right=width-1; local grooveB=height-margin; local grooveR=width-margin; local grooveIn1=inner+1; local grooveB1=grooveB-1; local bandB=height-margin; local bandR=width-margin; local bandMidB=height-margin-1
    local hi=0.22*strength/100; local lo=0.28*strength/100; local glo=0.20*strength/100
    file:rectOver(0,0,right,margin-1,{255,255,255,hi*255}); file:rectOver(0,margin,margin-1,bandMidB,{255,255,255,hi*255})
    file:rectOver(0,bandB,right,bottom,{0,0,0,lo*255}); file:rectOver(bandR,margin,right,bandMidB,{0,0,0,lo*255})
    file:rectOver(inner,inner,grooveR,inner,{0,0,0,glo*255}); file:rectOver(inner,grooveIn1,inner,grooveB,{0,0,0,glo*255})
    file:rectOver(margin,grooveB,grooveR,grooveB,{255,255,255,glo*255}); file:rectOver(grooveR,margin,grooveR,grooveB1,{255,255,255,glo*255})
end

local function shadeLowered(file,width,height,strength,recessed)
    strength=strength or 100; local bottom=height-1; local right=width-1; local midB=height-2; local face=file:median();
    file:rect(0,0,right,0,{face,face,face,255}); file:rect(0,bottom,right,bottom,{face,face,face,255}); file:rect(0,1,0,midB,{face,face,face,255}); file:rect(right,1,right,midB,{face,face,face,255})
    local sh=0.25*strength/100
    if recessed then
        local hi=0.20*strength/100; file:rectOver(0,0,right,0,{0,0,0,sh*255}); file:rectOver(0,1,0,midB,{0,0,0,sh*255}); file:rectOver(0,bottom,right,bottom,{255,255,255,hi*255}); file:rectOver(right,1,right,midB,{255,255,255,hi*255})
    else
        file:rectOver(0,0,right,0,{0,0,0,sh*255}); file:rectOver(0,bottom,right,bottom,{0,0,0,sh*255}); file:rectOver(0,1,0,midB,{0,0,0,sh*255}); file:rectOver(right,1,right,midB,{0,0,0,sh*255})
    end
end

local function shadeUniform(file,width,height,margin,strength)
    strength=strength or 100; local bottom=height-1; local right=width-1; local bandB=height-margin; local bandR=width-margin; local bandMidB=height-margin-1; local grooveT=margin-1; local grooveB=height-margin; local grooveL=margin-1; local grooveR=width-margin; local sh=0.25*strength/100; local c={0,0,0,sh*255}
    file:rectOver(0,0,right,margin-1,c); file:rectOver(0,bandB,right,bottom,c); file:rectOver(0,margin,margin-1,bandMidB,c); file:rectOver(bandR,margin,right,bandMidB,c); file:rectOver(0,grooveT,right,grooveT,c); file:rectOver(0,grooveB,right,grooveB,c); file:rectOver(grooveL,margin,grooveL,bandMidB,c); file:rectOver(grooveR,margin,grooveR,bandMidB,c)
end

local function makeTwoTone(width,height,margin,outerBand,outerTile,innerTile,shading)
    local base=magick.tile(width,height,outerTile); local inner=magick.tile(width-outerBand*2,height-outerBand*2,innerTile); base:over(inner,outerBand,outerBand)
    if shading=='raised' then shadeRaised(base,width,height,margin,100) else shadeUniform(base,width,height,margin,100) end
    for y=margin,height-margin-1 do for x=margin,width-margin-1 do local r,g,b=base:get(x,y); base:set(x,y,r,g,b,0) end end
    return base
end

local function makeFilled(width,height,margin,outerBand,outerTile,innerTile,centerTile,shading,strength)
    local base=magick.tile(width,height,outerTile); base:over(magick.tile(width-outerBand*2,height-outerBand*2,innerTile),outerBand,outerBand); base:over(magick.tile(width-margin*2,height-margin*2,centerTile),margin,margin)
    if shading=='recessed' then shadeLowered(base,width,height,strength,true) elseif shading=='lowered' then shadeLowered(base,width,height,strength,false) else shadeRaised(base,width,height,margin,strength) end
    return base
end

function M.generateChromeSources(options)
    options=options or {}; local materialPath=assert(options.material,'h3-tools: --material path required'); local output=options.output or 'h3ui-textures'; local size=512; local seed=options.seed or 3301
    ensureDir(output); local textureDir=jess.fs.join(output,'Textures'); ensureDir(textureDir); textureDir=jess.fs.join(textureDir,'h3ui'); ensureDir(textureDir)
    local src=magick.read(materialPath); local cropSize=math.min(1024,src.width,src.height); local cropX=options.cropX or 0; local cropY=options.cropY or 0
    if cropX<0 or cropY<0 or cropX+cropSize>src.width or cropY+cropSize>src.height then error('material crop does not fit image',2) end
    local field=src:crop(cropSize,cropSize,cropX,cropY):grayscale():resize(size,size):grayscale(); local blurred=magick.gaussianBlur(field,12); field=magick.mathCompose(field,blurred,0,1,-1,0.5):contrastStretch(1,1):grayscale():sigmoidalContrast(2,0.5):grayscale()
    local frameOuter=toneMaterial(field,50,100); local controlOuter=toneMaterial(field,48,96); local controlInner=toneMaterial(field,56,100); local controlPressed=toneMaterial(field,30,68)
    local function write(name,img) magick.write(jess.fs.join(textureDir,name),img) end
    write('frame_thick.dds',makeTwoTone(512,512,4,2,frameOuter,frameOuter,'uniform'))
    write('frame_thin.dds',makeTwoTone(504,504,2,1,frameOuter,frameOuter,'uniform'))
    write('frame_button.dds',makeTwoTone(136,24,4,2,controlOuter,controlOuter,'raised'))
    write('frame_caption.dds',makeFilled(260,20,2,1,frameOuter,frameOuter,frameOuter,'lowered',160))
    write('frame_pin_up.dds',makeFilled(20,20,2,1,controlInner,controlInner,controlOuter,'raised',140))
    write('frame_pin_down.dds',makeFilled(20,20,2,1,controlInner,controlInner,controlPressed,'recessed',140))
    local arrows={
      up={{{1.5,12.5},{8,2},{14.5,12.5}},{{3.5,11.5},{8,4.5},{12.5,11.5}}},
      down={{{1.5,3.5},{8,14},{14.5,3.5}},{{3.5,4.5},{8,11.5},{12.5,4.5}}},
      left={{{12.5,1.5},{2,8},{12.5,14.5}},{{11.5,3.5},{4.5,8},{11.5,12.5}}},
      right={{{3.5,1.5},{14,8},{3.5,14.5}},{{4.5,3.5},{11.5,8},{4.5,12.5}}},
    }
    for dir,pts in arrows do local a=magick.new(16,16); a:polygon(pts[1],controlInner); a:polygon(pts[2],controlOuter); write('arrow_'..dir..'.dds',a) end
    local grad=magick.verticalGradient(16,8,{245,245,245,255},{92,92,92,255}); grad=magick.addGaussianNoise(grad,seed+20,0.035):grayscale(); write('meter_fill.dds',grad)
    write('flat_white.dds',magick.new(8,8,'#ffffff'))
    return {output=textureDir,cropX=cropX,cropY=cropY,files=12}
end

local atlasX={thick=0,thin=4,button=56,caption=56,pinUp=328,pinDown=400,scrollUp=320,scrollDown=356,scrollLeft=392,scrollRight=428}
local atlasY={thick=0,thin=4,button=56,caption=160,pinUp=56,pinDown=56,scrollUp=128,scrollDown=128,scrollLeft=128,scrollRight=128}
local specs={
  thick={'frame_thick.dds',512,512,4}, thin={'frame_thin.dds',504,504,2}, button={'frame_button.dds',136,24,4}, caption={'frame_caption.dds',260,20,2}, pinUp={'frame_pin_up.dds',20,20,2}, pinDown={'frame_pin_down.dds',20,20,2},
  scrollUp={'arrow_up.dds',16,16,0}, scrollDown={'arrow_down.dds',16,16,0}, scrollLeft={'arrow_left.dds',16,16,0}, scrollRight={'arrow_right.dds',16,16,0},
}

-- Full H3UI + legacy Morrowind nested-atlas recomposer.
local sourceExts={'dds','bmp','tga','png'}
local function findSource(directory,basename)
    for _,e in sourceExts do local p=jess.fs.join(directory,basename..'.'..e); if jess.fs.exists(p) then return p end end
    return nil
end
local function findCornerSource(directory,prefix,corner)
    return findSource(directory,prefix..'_'..corner..'_corner') or findSource(directory,prefix..'_'..corner)
end
local function findScrollSource(directory,direction)
    return findSource(directory,'menu_scroll_'..direction) or findSource(directory,'omw_menu_scroll_'..direction)
end
local function grayMorrowind(path)
    local im=magick.read(path); return magick.modulate(im,150,0)
end
local function composeLegacyFrame(directory,prefix,targetW,targetH,centerName)
    local tlp=assert(findCornerSource(directory,prefix,'top_left'),'missing '..prefix..' top_left')
    local trp=assert(findCornerSource(directory,prefix,'top_right'),'missing '..prefix..' top_right')
    local blp=assert(findCornerSource(directory,prefix,'bottom_left'),'missing '..prefix..' bottom_left')
    local brp=assert(findCornerSource(directory,prefix,'bottom_right'),'missing '..prefix..' bottom_right')
    local topp=assert(findSource(directory,prefix..'_top'),'missing '..prefix..' top')
    local bottomp=assert(findSource(directory,prefix..'_bottom'),'missing '..prefix..' bottom')
    local leftp=assert(findSource(directory,prefix..'_left'),'missing '..prefix..' left')
    local rightp=assert(findSource(directory,prefix..'_right'),'missing '..prefix..' right')
    local tl=grayMorrowind(tlp); local tr=grayMorrowind(trp); local bl=grayMorrowind(blp); local br=grayMorrowind(brp)
    local top=grayMorrowind(topp); local bottom=grayMorrowind(bottomp); local left=grayMorrowind(leftp); local right=grayMorrowind(rightp)
    local leftW,topH=tl.width,tl.height; local rightW=tr.width; local bottomH=bl.height
    if leftW~=topH or rightW~=leftW or bottomH~=topH then error('non-uniform source borders are not supported for '..prefix,2) end
    local centerW=targetW-leftW-rightW; local centerH=targetH-topH-bottomH
    if centerW<=0 or centerH<=0 then error('target too small for '..prefix,2) end
    local out=magick.new(targetW,targetH)
    out:over(tl,0,0); out:over(top:resize(centerW,topH),leftW,0); out:over(tr,targetW-rightW,0)
    out:over(left:resize(leftW,centerH),0,topH); out:over(right:resize(rightW,centerH),targetW-rightW,topH)
    out:over(bl,0,targetH-bottomH); out:over(bottom:resize(centerW,bottomH),leftW,targetH-bottomH); out:over(br,targetW-rightW,targetH-bottomH)
    if centerName then
        local cp=assert(findSource(directory,prefix..'_'..centerName),'missing '..prefix..'_'..centerName)
        out:over(grayMorrowind(cp):resize(centerW,centerH),leftW,topH)
    end
    return out,leftW
end
local function composeLegacyNatural(directory,prefix,centerName)
    local tl=magick.read(assert(findCornerSource(directory,prefix,'top_left')))
    local top=magick.read(assert(findSource(directory,prefix..'_top')))
    local left=magick.read(assert(findSource(directory,prefix..'_left')))
    local w=tl.width+top.width+tl.width; local h=tl.height+left.height+tl.height
    return composeLegacyFrame(directory,prefix,w,h,centerName)
end

function M.recomposeChrome(options)
    options=options or {}; local h3dir=options.h3ui; local mwdir=options.morrowind; local openmw=options.openmw
    if not h3dir and not mwdir then error('h3-tools: one of h3ui or morrowind is required',2) end
    if mwdir and not openmw then openmw=mwdir end
    local output=options.output or 'chrome-atlases'; ensureDir(output); local textures=jess.fs.join(output,'Textures'); ensureDir(textures); textures=jess.fs.join(textures,'h3ui'); ensureDir(textures)
    local themes={}
    if h3dir then
        local loaded={}; local borders={}
        for key,sp in specs do local p=assert(findSource(h3dir,string.gsub(sp[1],'%.dds$','')),'missing H3UI '..sp[1]); local im=magick.read(p); if im.width~=sp[2] or im.height~=sp[3] then error(key..' source has wrong size',2) end; loaded[key]=im; borders[key]=sp[4] end
        themes.h3ui={images=loaded,borders=borders,path='textures/h3ui/h3ui_chrome.dds'}
    end
    if mwdir then
        local images,borders={},{}
        images.thick,borders.thick=composeLegacyFrame(mwdir,'menu_thick_border',512,512,nil)
        images.thin,borders.thin=composeLegacyFrame(mwdir,'menu_thin_border',504,504,nil)
        images.button,borders.button=composeLegacyNatural(mwdir,'menu_button_frame',nil)
        images.caption,borders.caption=composeLegacyNatural(mwdir,'menu_head_block','middle')
        images.pinUp,borders.pinUp=composeLegacyNatural(mwdir,'menu_rightbuttonup','center')
        images.pinDown,borders.pinDown=composeLegacyNatural(mwdir,'menu_rightbuttondown','center')
        for _,dir in {'up','down','left','right'} do local key='scroll'..string.upper(string.sub(dir,1,1))..string.sub(dir,2); images[key]=magick.read(assert(findScrollSource(openmw,dir),'missing scroll '..dir)); borders[key]=0 end
        themes.morrowind={images=images,borders=borders,path='textures/h3ui/morrowind_chrome.dds'}
    end
    local order={'thin','button','caption','pinUp','pinDown','scrollUp','scrollDown','scrollLeft','scrollRight'}
    for name,t in themes do
        local atlas=magick.new(512,512); atlas:over(t.images.thick,0,0)
        for _,key in order do local im=t.images[key]; local x,y=atlasX[key],atlasY[key]; if x+im.width>512 or y+im.height>512 then error(name..'/'..key..' does not fit atlas',2) end; atlas:over(im,x,y) end
        magick.write(jess.fs.join(textures,name..'_chrome.dds'),atlas)
        if name=='morrowind' then local chrome=jess.fs.join(textures,'chrome'); ensureDir(chrome); jess.fs.copy(jess.fs.join(textures,'morrowind_chrome.dds'),jess.fs.join(chrome,'morrowind.dds')) end
    end
    local lines={"-- Generated by recompose_chrome_atlases.sh.","local util = require 'openmw.util'","","local function region(path, x, y, width, height, sourceBorder, thickness, center, tintable)","  return {","    path = path,","    offset = util.vector2(x, y),","    size = util.vector2(width, height),","    sourceBorder = sourceBorder,","    thickness = thickness,","    center = center,","    tintable = tintable,","  }","end","","return {"}
    local themeOrder={}; if themes.h3ui then themeOrder[#themeOrder+1]='h3ui' end; if themes.morrowind then themeOrder[#themeOrder+1]='morrowind' end
    for _,name in themeOrder do local t=themes[name]; lines[#lines+1]='  '..name..' = {'; lines[#lines+1]='    frame = {'
        for _,key in {'thin','thick','button','caption','pinUp','pinDown'} do local im=t.images[key]; local thickness=(key=='thin' and 2) or ((key=='thick' or key=='button') and 4) or 2; local center=(key=='caption' or key=='pinUp' or key=='pinDown') and 'true' or 'false'; lines[#lines+1]=string.format("      %s = region('%s', %d, %d, %d, %d, %d, %d, %s, true),",key,t.path,atlasX[key],atlasY[key],im.width,im.height,t.borders[key],thickness,center) end
        lines[#lines+1]='    },'; lines[#lines+1]='    scroll = {'
        for _,dir in {'up','down','left','right'} do local key='scroll'..string.upper(string.sub(dir,1,1))..string.sub(dir,2); local im=t.images[key]; lines[#lines+1]=string.format("      %s = region('%s', %d, %d, %d, %d, nil, nil, false, true),",dir,t.path,atlasX[key],atlasY[key],im.width,im.height) end
        lines[#lines+1]='    },'; lines[#lines+1]='  },'
    end
    lines[#lines+1]='}'; lines[#lines+1]=''
    local manifestPath=jess.fs.join(output,'h3ui_chrome_manifest.lua'); jess.fs.write(manifestPath,table.concat(lines,'\n'))
    return {manifest=manifestPath,output=textures,h3ui=themes.h3ui and jess.fs.join(textures,'h3ui_chrome.dds') or nil,morrowind=themes.morrowind and jess.fs.join(textures,'morrowind_chrome.dds') or nil}
end

return M
