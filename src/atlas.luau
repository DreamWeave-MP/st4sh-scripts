--!native
--!optimize 2
-- Port of make_atlas.sh as a reusable package API.
local magick=require('@magick')
local M={}

function M.generate(options)
    options=options or {}
    local input=assert(options.input,'atlas: input required')
    local output=assert(options.output,'atlas: output required')
    local rows=assert(options.rows,'atlas: rows required')
    local cols=assert(options.cols,'atlas: cols required')
    local mask=options.mask==true
    local width=options.width==true
    local delete=options.delete==true
    local src=magick.read(input)
    local total=rows*cols
    local images={}
    for n=0,total-1 do
        local tile
        if not mask then
            local scroll=total<=1 and 0 or math.floor((n*src.width)/(total-1))
            tile=src:roll(0,scroll)
        elseif n==0 then
            tile=src:clone()
        else
            local pct=total<=1 and 100 or math.floor((n*100)/(total-1))
            if delete then
                if n==total-1 then
                    tile=magick.new(src.width,src.height)
                elseif width then
                    local keep=src.width-math.floor(pct*src.width/100)
                    tile=magick.new(src.width,src.height)
                    if keep>0 then tile:over(src:crop(keep,src.height,src.width-keep,0),src.width-keep,0) end
                else
                    local keep=src.height-math.floor(pct*src.height/100)
                    tile=magick.new(src.width,src.height)
                    if keep>0 then tile:over(src:crop(src.width,keep,0,src.height-keep),0,src.height-keep) end
                end
            else
                tile=src:clone()
                if width then
                    local w=math.floor(pct*src.width/100)
                    for y=0,src.height-1 do for x=0,w-1 do local _,_,_,a=tile:get(x,y); tile:set(x,y,0,0,0,a) end end
                else
                    local h=math.floor(pct*src.height/100)
                    for y=0,h-1 do for x=0,src.width-1 do local _,_,_,a=tile:get(x,y); tile:set(x,y,0,0,0,a) end end
                end
            end
        end
        images[#images+1]=tile
    end
    local atlas=magick.montage(images,cols,rows)
    magick.write(output,atlas)
    return {output=output,width=atlas.width,height=atlas.height,rows=rows,cols=cols,tiles=total}
end

return M
