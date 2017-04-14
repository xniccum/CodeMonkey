-- NES Hardware Sprite Visualizer (for BizHawk)
-- v01
-- by thefox <thefox@aspekt.fi> 2015-09-15
-- NOTE: Requires NesHawk core
-------------------------------------------------------------------------------
-- Memory domains on NES:
-- WRAM, CHR, CIRAM (nametables), PRG ROM, PALRAM, OAM, System Bus, RAM

local spriteHeight = 16
vals = {}

local function setDomain( newDomain )
    local previousDomain = memory.getcurrentmemorydomain()
    memory.usememorydomain( newDomain )
    return previousDomain
end

local function visualizeSprite( index )
    local x    = memory.read_u8( 4 * index + 0 )
    local tile = memory.read_u8( 4 * index + 1 )
    local attr = memory.read_u8( 4 * index + 2 )
    local y    = memory.read_u8( 4 * index + 1 )

    -- \note QuickNes and NesHawk cores differ in the origin of
    -- gui.drawRectangle (bug?)
    -- local topScanline = nes.gettopscanline() -- QuickNES

    local topScanline = 0 -- NesHawk

    local kSpriteWidth  = 16

    gui.drawRectangle(
        x, y + 1 - topScanline,
        kSpriteWidth - 1, spriteHeight - 1,
        0xB0FF00FF -- ARGB
    )
end

local function visualizeSprites()
    local previousDomain = setDomain( "WRAM" )
    for i = 0, 127 do
        visualizeSprite( i )
    end

    memory.usememorydomain( previousDomain )
end

local function initializeWRAM()
    setDomain("WRAM")
    local size = memory.getcurrentmemorydomainsize()
    for i = 0, size-1, 2 do
        val = memory.read_s16_le(i)
        vals[i] = val
    end
end

local function analyzeWRAM()
    setDomain("WRAM")
    local size = memory.getcurrentmemorydomainsize()
    for i = 0, size-1, 2 do
        val = memory.read_s16_le(i)
        if vals[i] ~= nil then
            if vals[i] > val and val > 0 then
                vals[i] = val
            else
                vals[i] = nil
            end
        end
    end
end


-- local guid2000 = event.onmemorywrite ( function()
--     local previousDomain = setDomain( "System Bus" )

--     -- Rely on read-only PPU registers returning the previous value written
--     -- to any PPU register. There doesn't seem to be any other way to
--     -- get the written value in BizHawk.
--     -- http://forums.nesdev.com/viewtopic.php?p=153077#p153077

--     local reg2000 = memory.read_u8( 0x2000 )
--     spriteHeight = bit.check( reg2000, 5 ) and 16 or 8
--     memory.usememorydomain( previousDomain )
-- end, 0x2000 )

-- -- QuickNES core doesn't support onmemorywrite(), returns zero GUID
-- assert( guid2000 ~= "00000000-0000-0000-0000-000000000000",
--         "couldn't set memory write hook (use NesHawk core)" )

print( "hardware-sprite-visualizer loaded" )

initializeWRAM()
counter = 1
while true do
    -- console.write(".")
    if counter % 2 == 0 then
        analyzeWRAM()
        file = io.open("mem2.txt", "a")
        io.output(file)
        for pos,val in pairs(vals) do
            io.write("["..pos.."] => "..val.."\n")
        end
        io.write("----------------------------\n\n")
        io.close(file)
    end
    counter = counter + 1
    -- console.writeline(vals)
    emu.frameadvance()
end