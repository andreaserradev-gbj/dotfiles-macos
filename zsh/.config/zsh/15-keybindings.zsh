# Line-editor key bindings.

# Option+Left/Right reach the shell as xterm Alt+arrow sequences, since Ghostty
# no longer rewrites them to esc:b / esc:f (see the ghostty config). Inside herdr
# the Alt+arrows move focus between panes and never get here; Alt+B / Alt+F still
# jump by word there.
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
