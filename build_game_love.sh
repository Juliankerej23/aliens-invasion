#!/usr/bin/env bash
set -euo pipefail
rm -f game.love
(cd game-source && zip -qr ../game.love .)
echo "Created game.love"
