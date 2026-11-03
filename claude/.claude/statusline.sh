#!/bin/bash
# statusline.sh — Claude Code status line.
#
# Claude Code pipes a JSON blob (model, workspace, cost, context window,
# transcript path) on stdin and prints whatever this writes to stdout.
# Layout, one line:
#
#   <project>[/subdir]  <branch> ↑ahead ↓behind +staged ~modified ?untracked
#   │ <model> · <effort> │ ctx ▰▰▰▱▱▱▱▱▱▱ 31% 62k/200k │ $0.42
#
# Colours are Catppuccin Mocha (truecolor), matching bat/delta/nvim.
# Must stay bash-3.2 clean: /bin/bash on macOS.

input=$(cat)

j() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

# --- palette (Catppuccin Mocha) ---------------------------------------------
c() { printf '\033[38;2;%sm' "$1"; }
RESET=$'\033[0m'
BLUE=$(c '137;180;250')
MAUVE=$(c '203;166;247')
GREEN=$(c '166;227;161')
YELLOW=$(c '249;226;175')
PEACH=$(c '250;179;135')
RED=$(c '243;139;168')
TEAL=$(c '148;226;213')
SUBTLE=$(c '108;112;134')
SEP=" ${SUBTLE}│${RESET} "

# --- project ----------------------------------------------------------------
cwd=$(j '.workspace.current_dir')
[ -z "$cwd" ] && cwd=$(j '.cwd')
[ -z "$cwd" ] && cwd=$PWD
proj_dir=$(j '.workspace.project_dir')
[ -z "$proj_dir" ] && proj_dir=$cwd

project="${proj_dir##*/}"
if [ "$cwd" != "$proj_dir" ] && [ "${cwd#"$proj_dir"/}" != "$cwd" ]; then
    project="$project/${cwd#"$proj_dir"/}"
fi
out="${BLUE}󰉋 ${project}${RESET}"

# --- git --------------------------------------------------------------------
# --no-optional-locks: the status line runs constantly; never contend with a
# git command the user (or Claude) is running in the same repo.
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    g() { git -C "$cwd" --no-optional-locks "$@" 2>/dev/null; }
    branch=$(g symbolic-ref --short HEAD || g rev-parse --short HEAD)
    seg="${MAUVE} ${branch}${RESET}"

    counts=$(g rev-list --left-right --count '@{upstream}...HEAD')
    if [ -n "$counts" ]; then
        behind=${counts%%[[:space:]]*}
        ahead=${counts##*[[:space:]]}
        [ "$ahead" -gt 0 ] && seg="$seg ${TEAL}↑${ahead}${RESET}"
        [ "$behind" -gt 0 ] && seg="$seg ${TEAL}↓${behind}${RESET}"
    fi

    staged=0 modified=0 untracked=0 conflicted=0
    while IFS= read -r line; do
        x=${line:0:1} y=${line:1:1}
        case "$x$y" in
            '??') untracked=$((untracked + 1)); continue ;;
            DD|AU|UD|UA|DU|AA|UU) conflicted=$((conflicted + 1)); continue ;;
        esac
        [ "$x" != ' ' ] && staged=$((staged + 1))
        [ "$y" != ' ' ] && modified=$((modified + 1))
    done < <(g status --porcelain)

    [ "$conflicted" -gt 0 ] && seg="$seg ${RED}!${conflicted}${RESET}"
    [ "$staged" -gt 0 ] && seg="$seg ${GREEN}+${staged}${RESET}"
    [ "$modified" -gt 0 ] && seg="$seg ${YELLOW}~${modified}${RESET}"
    [ "$untracked" -gt 0 ] && seg="$seg ${SUBTLE}?${untracked}${RESET}"
    if [ $((staged + modified + untracked + conflicted)) -eq 0 ]; then
        seg="$seg ${GREEN}✓${RESET}"
    fi
    out="$out  $seg"
fi

# --- model ------------------------------------------------------------------
model=$(j '.model.display_name')
[ -n "$model" ] && out="$out$SEP${PEACH}${model}${RESET}"

# --- effort -----------------------------------------------------------------
# Reasoning effort (low/medium/high/xhigh/max), shown right after the model it
# applies to. Older Claude Code versions do not send it; then nothing shows.
effort=$(j '.effort.level')
[ -n "$effort" ] && out="$out ${SUBTLE}·${RESET} ${MAUVE}${effort}${RESET}"

# --- context window ---------------------------------------------------------
# Prefer the numbers Claude Code reports; fall back to the last assistant
# message's usage in the transcript for versions that do not send them.
size=$(j '.context_window.context_window_size')
[ -z "$size" ] && size=200000
pct=$(j '.context_window.used_percentage')
used=""
cu='.context_window.current_usage'
if [ -n "$(j "$cu")" ]; then
    used=$(j "($cu.input_tokens // 0) + ($cu.cache_creation_input_tokens // 0) + ($cu.cache_read_input_tokens // 0)")
fi
if [ -z "$used" ] || [ "$used" = 0 ]; then
    transcript=$(j '.transcript_path')
    if [ -n "$transcript" ] && [ -f "$transcript" ]; then
        used=$(tail -n 200 "$transcript" | jq -rs '
            [ .[] | select(.type == "assistant" and .message.usage != null
                           and (.isSidechain | not)) ] | last | .message.usage
            | if . == null then empty else
              (.input_tokens // 0) + (.cache_creation_input_tokens // 0)
              + (.cache_read_input_tokens // 0) end' 2>/dev/null)
    fi
fi
if [ -z "$pct" ] && [ -n "$used" ]; then
    pct=$((used * 100 / size))
fi
if [ -n "$pct" ]; then
    pct=${pct%%.*}
    if [ "$pct" -ge 80 ]; then col=$RED
    elif [ "$pct" -ge 50 ]; then col=$YELLOW
    else col=$GREEN; fi
    filled=$(( (pct + 5) / 10 )); [ "$filled" -gt 10 ] && filled=10
    bar=""
    i=0; while [ $i -lt 10 ]; do
        if [ $i -lt "$filled" ]; then bar="${bar}▰"; else bar="${bar}▱"; fi
        i=$((i + 1))
    done
    ctx="${SUBTLE}ctx${RESET} ${col}${bar} ${pct}%${RESET}"
    if [ -n "$used" ] && [ "$used" != 0 ]; then
        ctx="$ctx ${SUBTLE}$((used / 1000))k/$((size / 1000))k${RESET}"
    fi
    out="$out$SEP$ctx"
fi

# --- cost -------------------------------------------------------------------
cost=$(j '.cost.total_cost_usd')
if [ -n "$cost" ]; then
    out="$out$SEP${SUBTLE}\$$(printf '%.2f' "$cost")${RESET}"
fi

printf '%s\n' "$out"
