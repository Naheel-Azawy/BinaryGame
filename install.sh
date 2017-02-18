#!/bin/bash
./compile.sh
mkdir -p ~/.local/games/bingame
mkdir -p ~/.config/bingame
cp ./bingame ~/.local/games/bingame/
cp ./bingame_ic.png ~/.local/games/bingame/
printf "[Desktop Entry]\nType=Application\nVersion=1.0\nName=Binary Game\nExec=$HOME/.local/games/bingame/bingame\nIcon=$HOME/.local/games/bingame/bingame_ic.png\nTerminal=false\n" > ~/.local/share/applications/bingame.desktop
