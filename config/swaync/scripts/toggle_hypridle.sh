#!/usr/bin/env bash
set +e # disable immediate exit on error

if pgrep -x "hypridle" > /dev/null; then
  {
    pkill hypridle
    notify-send -u "critical" -a "swaync" "󰾪 Coffee mode disabled" "The device will suspend"
  } >/dev/null 2>&1 || :
else
  {
    hypridle &
    notify-send -u "critical" -a "swaync" "󰅶 Coffee mode enabled" "The device won't suspend"
  } >/dev/null 2>&1 || :
fi

exit 0
