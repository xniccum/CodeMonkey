-- NES Hardware Sprite Visualizer (for BizHawk)
-- v01
-- by thefox <thefox@aspekt.fi> 2015-09-15
-- NOTE: Requires NesHawk core
-------------------------------------------------------------------------------
-- Memory domains on NES:
-- WRAM, CHR, CIRAM (nametables), PRG ROM, PALRAM, OAM, System Bus, RAM

local spriteHeight = 16

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
    local previousDomain = setDomain( "OAM" )
    for i = 0, 10 do
        visualizeSprite( 0 )
    end

    memory.usememorydomain( previousDomain )
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

while true do
    visualizeSprites()
    emu.frameadvance()
end