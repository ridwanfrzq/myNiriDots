#!/usr/bin/env bash
# WallSelect for Niri + swww
# Based on gh0stzk's WallSelect (Hyprland version)
# Modified for Niri compositor by Ridwan & ChatGPT 🌀

wall_dir="$HOME/Pictures/Wallpapers"
cacheDir="$HOME/.cache/wallcache"

[ -d "$cacheDir" ] || mkdir -p "$cacheDir"

# Get all monitors from swww (assuming swww-daemon is running)
monitors=$(swww query | grep "Output" | awk '{print $2}')

# Estimate width for icon size (no hyprctl available)
# Default icon size ~100px for fullHD
icon_size=100
rofi_override="element-icon{size:${icon_size}px;}"
rofi_command="rofi -i -show -dmenu -theme $HOME/.config/rofi/applets/wallSelect.rasi -theme-str $rofi_override"

get_optimal_jobs() {
    local cores=$(nproc)
    (( cores <= 2 )) && echo 2 || echo $(( (cores > 4) ? 4 : cores-1 ))
}
PARALLEL_JOBS=$(get_optimal_jobs)

process_image() {
    local imagen="$1"
    local nombre_archivo=$(basename "$imagen")
    local cache_file="${cacheDir}/${nombre_archivo}"
    local md5_file="${cacheDir}/.${nombre_archivo}.md5"
    local lock_file="${cacheDir}/.lock_${nombre_archivo}"

    local current_md5=$(xxh64sum "$imagen" | cut -d' ' -f1)

    (
        flock -x 200
        if [ ! -f "$cache_file" ] || [ ! -f "$md5_file" ] || [ "$current_md5" != "$(cat "$md5_file" 2>/dev/null)" ]; then
            magick "$imagen" -resize 500x500^ -gravity center -extent 500x500 "$cache_file"
            echo "$current_md5" > "$md5_file"
        fi
        rm -f "$lock_file"
    ) 200>"$lock_file"
}

export -f process_image
export wall_dir cacheDir

rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

find "$wall_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) -print0 | \
    xargs -0 -P "$PARALLEL_JOBS" -I {} bash -c 'process_image "{}"'

# Cleanup orphan cache
for cached in "$cacheDir"/*; do
    [ -f "$cached" ] || continue
    original="${wall_dir}/$(basename "$cached")"
    if [ ! -f "$original" ]; then
        nombre_archivo=$(basename "$cached")
        rm -f "$cached" \
            "${cacheDir}/.${nombre_archivo}.md5" \
            "${cacheDir}/.lock_${nombre_archivo}"
    fi
done

rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

if pidof rofi > /dev/null; then
  pkill rofi
fi

wall_selection=$(find "${wall_dir}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -print0 |
    xargs -0 basename -a |
    LC_ALL=C sort -V |
    while IFS= read -r A; do
        if [[ "$A" =~ \.gif$ ]]; then
            printf "%s\n" "$A"
        else
            printf '%s\x00icon\x1f%s/%s\n' "$A" "${cacheDir}" "$A"
        fi
    done | $rofi_command)

SCHEMEFILE="$HOME/.cache/scheme"
[[ ! -f "$SCHEMEFILE" ]] && echo "dark" > "$SCHEMEFILE"
read -r scheme < "$SCHEMEFILE"

# Apply wallpaper with swww
if [[ -n "$wall_selection" ]]; then
    for mon in $monitors; do
        swww img "${wall_dir}/${wall_selection}" --outputs "$mon" --transition-type grow --transition-fps 60
    done
    matugen image "${wall_dir}/${wall_selection}" -m "$scheme"
fi

