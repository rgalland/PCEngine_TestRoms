#!/bin/bash
VRAM_TILES_ADDR=0x0800
VRAM_TILES_OFFSET=$((VRAM_TILES_ADDR/16))
echo "PCE tiles must be stored at "$VRAM_TILES_ADDR" to use the generated map" 
./../../superfamiconv -v -i loading.png -p loading.pal -t loading.chr -m loading.map -M pce -B 4 -W 8 -H 8 -T $VRAM_TILES_OFFSET --out-tiles-image loading_tiles.png

#./superfamiconv map -v -i Waifu_locolor.png -p Waifu_locolor.pal -t Waifu_locolor.chr -d Waifu_locolor.map -M pce -B 4 -W 8 -H 8 -T $VRAM_TILES_OFFSET --map-width 64 --map-height 28

