#!/bin/bash

# Cek scheme saat ini
current_scheme=$(cat ~/.cache/scheme 2>/dev/null || echo "light")

# Toggle scheme
if [ "$current_scheme" = "dark" ]; then
    chsch light
    swaync-client -rs
else
    chsch dark
    swaync-client -rs
fi
