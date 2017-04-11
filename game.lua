local game = {}
function game.getPositions()
    if gameinfo.getromname() == "Super Mario World (USA)" then
        marioX = memory.read_s16_le(0x94)
        marioY = memory.read_s16_le(0x96)

        local layer1x = memory.read_s16_le(0x1A);
        local layer1y = memory.read_s16_le(0x1C);

        screenX = marioX-layer1x
        screenY = marioY-layer1y
    elseif gameinfo.getromname() == "Super Mario Bros." then
        marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
        marioY = memory.readbyte(0x03B8)+16

        screenX = memory.readbyte(0x03AD)
        screenY = memory.readbyte(0x03B8)
    end
end

function game.getTile(dx, dy)
    if gameinfo.getromname() == "Super Mario World (USA)" then
        x = math.floor((marioX+dx+8)/16)
        y = math.floor((marioY+dy)/16)

        return memory.readbyte(0x1C800 + math.floor(x/0x10)*0x1B0 + y*0x10 + x%0x10)
    elseif gameinfo.getromname() == "Super Mario Bros." then
        local x = marioX + dx + 8
        local y = marioY + dy - 16
        local page = math.floor(x/256)%2

        local subx = math.floor((x%256)/16)
        local suby = math.floor((y - 32)/16)
        local addr = 0x500 + page*13*16+suby*16+subx

        if suby >= 13 or suby < 0 then
            return 0
        end

        if memory.readbyte(addr) ~= 0 then
            return 1
        else
            return 0
        end
    end
end

function game.getSprites()
    if gameinfo.getromname() == "Super Mario World (USA)" then
        local sprites = {}
        for slot=0,11 do
            local status = memory.readbyte(0x14C8+slot)
            if status ~= 0 then
                spritex = memory.readbyte(0xE4+slot) + memory.readbyte(0x14E0+slot)*256
                spritey = memory.readbyte(0xD8+slot) + memory.readbyte(0x14D4+slot)*256
                sprites[#sprites+1] = {["x"]=spritex, ["y"]=spritey}
            end
        end     
        
        return sprites
    elseif gameinfo.getromname() == "Super Mario Bros." then
        local sprites = {}
        for slot=0,4 do
            local enemy = memory.readbyte(0xF+slot)
            if enemy ~= 0 then
                local ex = memory.readbyte(0x6E + slot)*0x100 + memory.readbyte(0x87+slot)
                local ey = memory.readbyte(0xCF + slot)+24
                sprites[#sprites+1] = {["x"]=ex,["y"]=ey}
            end
        end
        
        return sprites
    end
end

function game.getExtendedSprites()
    if gameinfo.getromname() == "Super Mario World (USA)" then
        local extended = {}
        for slot=0,11 do
            local number = memory.readbyte(0x170B+slot)
            if number ~= 0 then
                spritex = memory.readbyte(0x171F+slot) + memory.readbyte(0x1733+slot)*256
                spritey = memory.readbyte(0x1715+slot) + memory.readbyte(0x1729+slot)*256
                extended[#extended+1] = {["x"]=spritex, ["y"]=spritey}
            end
        end
        return extended
    elseif gameinfo.getromname() == "Super Mario Bros." then
        return {}
    end
end

function game.getInputs()
    getPositions()
    
    sprites = getSprites()
    extended = getExtendedSprites()
    
    local inputs = {}
    
    for dy=-BoxRadius*16,BoxRadius*16,16 do
        for dx=-BoxRadius*16,BoxRadius*16,16 do
            inputs[#inputs+1] = 0
            
            tile = getTile(dx, dy)
            if tile == 1 and marioY+dy < 0x1B0 then
                inputs[#inputs] = 1
            end
            
            for i = 1,#sprites do
                distx = math.abs(sprites[i]["x"] - (marioX+dx))
                disty = math.abs(sprites[i]["y"] - (marioY+dy))
                if distx <= 8 and disty <= 8 then
                    inputs[#inputs] = -1
                end
            end

            for i = 1,#extended do
                distx = math.abs(extended[i]["x"] - (marioX+dx))
                disty = math.abs(extended[i]["y"] - (marioY+dy))
                if distx < 8 and disty < 8 then
                    inputs[#inputs] = -1
                end
            end
        end
    end
    return inputs
end

return game