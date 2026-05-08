#!/bin/bash
# Claude Code StatusLine Command
# Designed to match the user's shell prompt aesthetic from ~/.bashrc

input=$(cat)

current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "unknown"' 2>/dev/null | sed "s|^$HOME|~|g")
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown"' 2>/dev/null)
model_version=$(echo "$input" | jq -r '.model.version // ""' 2>/dev/null)
session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null)

# Colors matching the shell prompt exactly
readonly LIGHTRED="1;31"
readonly LIGHTGREEN="1;32"
readonly BROWN="0;33"
readonly YELLOW="1;33"
readonly BLUE="0;34"
readonly LIGHTBLUE="1;34"
readonly CYAN="0;36"
readonly LIGHTCYAN="1;36"
readonly LIGHTMAGENTA="1;35"
readonly DARKGRAY="1;30"
readonly NOCOLOR="0"

# Function to get current time in [HH:MM] format
get_time() {
    printf "[\\033[${CYAN}m$(date '+%H:%M')\\033[${NOCOLOR}m]"
}

# Function to get abbreviated working directory
get_directory() {
    local pwd="$PWD"
    # Home directory abbreviation
    [[ "$pwd" == "$HOME"* ]] && pwd="~${pwd#$HOME}"

    # Abbreviate long paths
    if [[ ${#pwd} -gt 30 ]]; then
        # Simple path abbreviation for older bash versions
        local dir_name=$(basename "$pwd")
        local parent_dir=$(dirname "$pwd")
        local parent_base=$(basename "$parent_dir")

        if [[ "$parent_dir" != "/" && "$parent_dir" != "$HOME" ]]; then
            pwd="../${parent_base:0:1}/${dir_name}"
        elif [[ "$parent_dir" == "/" ]]; then
            pwd="${pwd}"
        else
            # Handle home directory abbreviations
            if [[ "$pwd" =~ ^~ ]]; then
                local home_abbrev="${pwd#~/}"
                if [[ ${#home_abbrev} -gt 20 ]]; then
                    home_abbrev="${home_abbrev:0:10}...${home_abbrev: -10}"
                fi
                pwd="~${home_abbrev}"
            fi
        fi
    fi

    printf "\\033[${DARKGRAY}m(\\033[${BROWN}m${pwd}\\033[${DARKGRAY}m)"
}

# Function to get git branch
get_git_branch() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi

    # Get current branch name
    local branch
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || \
              git rev-parse --short HEAD 2>/dev/null || \
              echo "unknown")

    # Clean up branch name
    branch="${branch#refs/heads/}"
    branch="${branch#remotes/}"

    # Only show if meaningful
    if [[ -n "$branch" && "$branch" != "unknown" ]]; then
        printf " \\033[${DARKGRAY}m(\\033[${CYAN}m${branch}\\033[${DARKGRAY}m)"
    fi
}

# Function to get virtual environment
get_virtual_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name="${VIRTUAL_ENV##*/}"
        printf " \\033[${DARKGRAY}m(\\033[${LIGHTMAGENTA}mvenv:${venv_name}\\033[${DARKGRAY}m)"
    fi
}

# Read the last usage entry's total context size from a session jsonl file.
# Total context = input + cache_read + cache_creation (all tokens the model saw).
# Echoes a number on success, nothing on failure.
read_last_tokens() {
    local file="$1"
    [ -f "$file" ] || return
    jq -rs '
        [ .[] | select(.message.usage) | .message.usage
          | ((.input_tokens // 0)
             + (.cache_read_input_tokens // 0)
             + (.cache_creation_input_tokens // 0)) ]
        | last // empty
    ' "$file" 2>/dev/null
}

# Sum cache_read / cache_creation across the whole session and echo the ratio.
# A high ratio means the prompt cache is paying off — most of what the model
# saw was served from cache rather than rewritten on every turn.
read_cache_ratio() {
    local file="$1"
    [ -f "$file" ] || return
    jq -rs '
        [.[] | select(.message.usage) | .message.usage] as $u
        | ([$u[].cache_read_input_tokens // 0] | add // 0) as $r
        | ([$u[].cache_creation_input_tokens // 0] | add // 0) as $c
        | if $c == 0 then empty else ($r / $c) end
    ' "$file" 2>/dev/null
}

# Pick the session file to read stats from. Prefers the transcript_path passed
# in by Claude Code; falls back to building it from session_id + cwd. If that
# file has no usage entries yet (fresh resume, no assistant turn yet), falls
# back to the most recently modified session file in the same project dir —
# that's the session we resumed from and its stats still reflect our context.
resolve_session_file() {
    local file="$transcript_path"
    if [ -z "$file" ] && [ -n "$session_id" ]; then
        local project_dir=$(echo "$current_dir" | sed "s|~|$HOME|g" | sed 's|/|-|g' | sed 's|^-||')
        file="$HOME/.claude/projects/-${project_dir}/${session_id}.jsonl"
    fi
    if [ -n "$(read_last_tokens "$file")" ]; then
        echo "$file"
        return
    fi
    ls -t "$(dirname "$file")"/*.jsonl 2>/dev/null | grep -v "^${file}$" | head -1
}

# Get token count for the current (possibly resumed) session.
get_token_count() {
    local session_file=$(resolve_session_file)
    local latest_tokens=$(read_last_tokens "$session_file")
    printf "Tokens: ${latest_tokens:-Unknown}"
}

# Get cache hit ratio (cache_read / cache_creation) across the session.
# Red below 5x — cache is being rewritten too often to pay for itself.
get_cache_ratio() {
    local session_file=$(resolve_session_file)
    local ratio=$(read_cache_ratio "$session_file")
    [ -z "$ratio" ] && return

    local color="$LIGHTGREEN"
    awk -v r="$ratio" 'BEGIN { exit !(r < 5) }' && color="$LIGHTRED"

    local formatted=$(printf "%.1f" "$ratio")
    printf " \\033[${DARKGRAY}mcache:\\033[${color}m${formatted}x\\033[${NOCOLOR}m"
}

# Main statusLine function
main() {
    # Build status line components
    local status_line=""

    # Add time (like prompt)
    #status_line+=" $(get_time)"

    # Add working directory (like prompt)
    status_line+=" $(get_directory)"

    # Add git branch (like prompt)
    #status_line+="$(get_git_branch)"

    # Add virtual environment (like prompt)
    #status_line+="$(get_virtual_env)"

    status_line+=" $(get_token_count)"
    status_line+="$(get_cache_ratio)"

    # Print the status line
    printf "%s\\n" "$status_line"
}

# Execute main function
main "$@"