--!native
--!optimize 2
-- Port of build_material_variants.sh. The catalog/source assets are caller-owned.
local magick=require('@magick')
local h3=require('@st4sh/scripts.h3')
local M={}

local function ensureTree(path)
    if jess.fs.exists(path) then
        if not jess.fs.isDir(path) then error(path..' exists and is not a directory',2) end
        return
    end
    local parent=jess.fs.parent(path)
    if parent and parent~=path and parent~='' and not jess.fs.exists(parent) then ensureTree(parent) end
    jess.fs.createDir(path)
end
local function splitTabs(line)
    local out={}; local from=1
    while true do
        local i=string.find(line,'\t',from,true)
        if not i then out[#out+1]=string.sub(line,from); break end
        out[#out+1]=string.sub(line,from,i-1); from=i+1
    end
    return out
end
local function jsonString(s)
    s=tostring(s or '')
    s=string.gsub(s,'\\','\\\\'); s=string.gsub(s,'"','\\"'); s=string.gsub(s,'\n','\\n'); s=string.gsub(s,'\r','\\r'); s=string.gsub(s,'\t','\\t')
    return '"'..s..'"'
end
local function rng(seed)
    local state=(seed or 3301)%2147483647; if state<=0 then state=1 end
    return function(n) state=(state*48271)%2147483647; return n<=1 and 0 or (state%n) end
end

function M.build(options)
    options=options or {}
    local materials=assert(options.materials,'material variants: materials TSV required')
    local sourceDir=assert(options.sourceDir,'material variants: sourceDir required')
    local installDir=assert(options.installDir,'material variants: installDir required')
    local wanted={}
    if options.stems then for _,v in options.stems do wanted[v]=true end end
    local filter=options.stems and #options.stems>0
    local rows={}
    local text=jess.fs.read(materials)
    local lineNo=0
    for line in string.gmatch(text,'([^\r\n]+)') do
        lineNo+=1
        if lineNo>1 and line~='' then
            local c=splitTabs(line)
            if #c>=9 then
                local row={stem=c[1],family=c[2],name=c[3],photo=c[4],cropX=tonumber(c[5]),cropY=tonumber(c[6]),url=c[7],author=c[8],license=c[9]}
                if not filter or wanted[row.stem] then rows[#rows+1]=row end
            end
        end
    end
    if #rows==0 then error('No materials matched.',2) end
    ensureTree(jess.fs.join(installDir,'chrome'))
    if options.staticDir then ensureTree(options.staticDir) end
    local random=rng(options.seed or 3301)
    local built={}
    local work=options.workDir or jess.fs.join(installDir,'.st4sh-material-work')
    ensureTree(work)
    for _,row in rows do
        local material=jess.fs.join(sourceDir,row.photo)
        local cropX,cropY=row.cropX or 0,row.cropY or 0
        if options.materialCrop then
            cropX,cropY=options.materialCrop[1],options.materialCrop[2]
        elseif options.randomCrop then
            local im=magick.read(material); local cropSize=math.min(1024,im.width,im.height)
            cropX=random(im.width-cropSize+1); cropY=random(im.height-cropSize+1)
        end
        local genOut=jess.fs.join(work,'gen-'..row.stem); local atlasOut=jess.fs.join(work,'atlas-'..row.stem)
        h3.generateChromeSources{material=material,cropX=cropX,cropY=cropY,output=genOut,seed=options.seed or 3301}
        local recomposed=h3.recomposeChrome{h3ui=jess.fs.join(genOut,'Textures','h3ui'),output=atlasOut}
        local dest=jess.fs.join(installDir,'chrome',row.stem..'.dds')
        jess.fs.copy(recomposed.h3ui,dest)
        if options.staticDir then
            -- Generic @magick has no WebP encoder yet; emit lossless PNG previews.
            magick.write(jess.fs.join(options.staticDir,row.stem..'.png'),magick.read(recomposed.h3ui))
        end
        built[#built+1]={stem=row.stem,cropX=cropX,cropY=cropY,output=dest}
    end
    if options.siteData then
        local chunks={'{\n  "materials": [\n'}
        for i,row in rows do
            if i>1 then chunks[#chunks+1]=',\n' end
            chunks[#chunks+1]=string.format('    {"id": %s, "family": %s, "name": %s, "photo": %s, "crop": [%d, %d], "url": %s, "author": %s, "license": %s}',jsonString(row.stem),jsonString(row.family),jsonString(row.name),jsonString(row.photo),row.cropX or 0,row.cropY or 0,jsonString(row.url),jsonString(row.author),jsonString(row.license))
        end
        chunks[#chunks+1]='\n  ]\n}\n'
        local parent=jess.fs.parent(options.siteData); if parent then ensureTree(parent) end
        jess.fs.write(options.siteData,table.concat(chunks))
    end
    return {built=built,count=#built}
end
return M
