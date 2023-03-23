#!/bin/bash
#VRAM_TILES_OFFSET=$((VRAM_TILES_ADDR/16))
#echo "PCE tiles must be stored at "$VRAM_TILES_ADDR" for this command to work" 
#../../gfx2pce -m! -po16 -gs16 -pc16 -pe0 -fpng -n -gb robot.png

#../../superfamiconv -v -i automata_sprites.png -p automata_sprites.pal -t automata_sprites.chr -M pce_sprite -B 4 -W 16 -H 16 --out-tiles-image automata_sprites_tiles.png
../../superfamiconv -v -i robot.png -p robot.pal -t robot.chr -M pce_sprite -B 4 -W 16 -H 16 -S --color-zero 0xFF00FF --out-tiles-image robot_tiles.png --out-palette-image robot_pal.png


