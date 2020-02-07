#!/bin/bash

echo "options snd-hda-intel model=dell-headset-dock" | sudo tee /etc/modprobe.d/axr-audio.conf
