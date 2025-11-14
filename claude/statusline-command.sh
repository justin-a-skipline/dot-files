#!/bin/bash
# Claude Code StatusLine Command
# Designed to match the user's shell prompt aesthetic from ~/.bashrc

input=$(cat)

current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "unknown"' 2>/dev/null | sed "s|^$HOME|~|g")
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown"' 2>/dev/null)
model_version=$(echo "$input" | jq -r '.model.version // ""' 2>/dev/null)
session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)

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
    pwd="${pwd#$HOME}"
    [[ "$pwd" != "${pwd#$HOME}" ]] && pwd="~${pwd}"

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

# Get token count
get_token_count() {
    local latest_tokens="Unknown"
    if [ -n "$session_id" ]; then
        # Convert current dir to session file path
        local project_dir=$(echo "$current_dir" | sed "s|~|$HOME|g" | sed 's|/|-|g' | sed 's|^-||')
        local session_file="$HOME/.claude/projects/-${project_dir}/${session_id}.jsonl"

        if [ -f "$session_file" ]; then
            # Get the latest input token count from the session file
            latest_tokens=$(tail -20 "$session_file" | jq -r 'select(.message.usage) | .message.usage | ((.input_tokens // 0) + (.cache_read_input_tokens // 0))' 2>/dev/null | tail -1)

        fi
    fi
    printf "Tokens: ${latest_tokens}"
}

# Main statusLine function
main() {
    # Build status line components
    local status_line=""

    # Add time (like prompt)
    status_line+=" $(get_time)"

    # Add working directory (like prompt)
    status_line+=" $(get_directory)"

    # Add git branch (like prompt)
    status_line+="$(get_git_branch)"

    # Add virtual environment (like prompt)
    status_line+="$(get_virtual_env)"

    status_line+=" $(get_token_count)"

    # Print the status line
    printf "%s\\n" "$status_line"
}

# Execute main function
main "$@"