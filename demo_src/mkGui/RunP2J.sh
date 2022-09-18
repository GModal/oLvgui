#!/bin/sh
#
# script to open a JACK port to the internal sound card output:
echo "pd2jack must be installed, JACK (or pipewire) running...\n"
pd2jack -v 1 -i -o -O 224.0.0.1 -p pd/noFX_dyna.pd

