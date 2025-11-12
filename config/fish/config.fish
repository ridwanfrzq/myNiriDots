if status is-interactive
    # Commands to run in interactive sessions can go here
    if test $TERM = "xterm-kitty"
         fastfetch
    end
end
starship init fish | source

fish_add_path /home/ridwanfrzq/.spicetify
