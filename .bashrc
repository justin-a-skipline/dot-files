# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

##### Colors ######################
# To have colors for ls and all grep commands such as grep, egrep and zgrep
function __set_ls_colors
{
	local LIGHTGRAY="0;37"
	local WHITE="1;37"
	local BLACK="0;30"
	local DARKGRAY="1;30"
	local RED="1;31"
	local LIGHTRED="0;31"
	local GREEN="0;32"
	local LIGHTGREEN="1;32"
	local BROWN="0;33"
	local YELLOW="1;33"
	local BLUE="0;34"
	local LIGHTBLUE="1;34"
	local MAGENTA="0;35"
	local LIGHTMAGENTA="1;35"
	local CYAN="0;36"
	local LIGHTCYAN="1;36"
	local NOCOLOR="0"

  export CLICOLOR=1
  # default, normal files
  LS_COLORS="no=${NOCOLOR}:fi=${NOCOLOR}"
  # directories
  LS_COLORS+=":di=${CYAN}"
  # symbolic links - color as item pointed to
  LS_COLORS+=":ln=target"
  # named pipe
  LS_COLORS+=":pi=${LIGHTGREEN}"
  # socket
  LS_COLORS+=":so=${LIGHTMAGENTA}"
  # block device
  LS_COLORS+=":bd=${LIGHTRED}"
  # character device
  LS_COLORS+=":cd=${RED}"
  # orphan symbolic link (broken)
  LS_COLORS+=":or=${BROWN}"
  # executable file
  LS_COLORS+=":ex=${LIGHTGREEN}"
  # extensions
  LS_COLORS+=":*.tar=${RED}"
  LS_COLORS+=":*.tgz=${RED}"
  LS_COLORS+=":*.zip=${RED}"
  LS_COLORS+=":*.gz=${RED}"
  LS_COLORS+=":*.bz2=${RED}"
  export LS_COLORS
}

__set_ls_colors


test -e "${HOME}/dot-files/z/z.sh" && source $_

PROMPT_COMMAND=""

stty -ixon
##### VIM Settings ##############
set -o vi
bind -f "${HOME}/dot-files/.inputrc"

export EDITOR="vim"
export VISUAL="vim"
export MANPAGER="vim -M +MANPAGER -c ':normal zR' -c ':setlocal nonumber' -"
alias vi='vim'

##### History Settings ##########
HISTCONTROL='erasedups:ignoreboth'
HISTSIZE=10000
HISTFILESIZE=10000
HISTIGNORE='?:??'
shopt -s histappend histverify
PROMPT_COMMAND+='history -a;'

##### Shell Settings ############
shopt -s checkwinsize
shopt -s globstar
shopt -s autocd
shopt -s cdspell dirspell

export LESS="-XFR"
export LESSCHARSET=utf-8
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

##### Completions ###############

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi

  for file in /usr/local/share/bash-completion/completions/*; do
    source "$file"
  done
fi

##### Aliases and Functions #####
alias pdfmerge='gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages -dCompressFonts=true -r150 -sOutputFile=gsout.pdf'

BATTERY_DEVICE='/org/freedesktop/UPower/devices/battery_BAT0'
alias battery="upower -i ${BATTERY_DEVICE} 2> /dev/null | grep percentage"

alias rg='rg --no-messages --vimgrep --max-filesize 5M --type-add work:include:cpp,c,asm --type-add work:\*.s43 --type-add zig:\*.zig'

alias clbin="curl -F 'clbin=<-' https://clbin.com"

alias ls='ls -Fh --color=auto'

alias find='find 2>/dev/null'

alias diskspace='du -S | sort -n -r'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias mkdir='mkdir -p'

alias ..='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'
alias ..5='cd ../../../../..'

alias gl='git log --oneline --decorate'
alias gs='git status --short --branch && gl -10'
alias gd='git diff'
alias gdc='gd --cached'

alias cpu_performance='echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
alias cpu_powersave='echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
alias cpu_freq='watch -n 1 "cat /proc/cpuinfo | grep \"^[c]pu MHz\""'

pdfdiff () {
  DIFFOUTPUT="$3"
  [ -z "$DIFFOUTPUT" ] && DIFFOUTPUT=diff.pdf
  diff-pdf --output-diff="$DIFFOUTPUT" "$1" "$2";
}

extract () {
	for archive in $*; do
		if [ -f $archive ] ; then
			case $archive in
				*.tar.bz2)   tar xvjf $archive    ;;
				*.tar.gz)    tar xvzf $archive    ;;
				*.bz2)       bunzip2 $archive     ;;
				*.rar)       rar x $archive       ;;
				*.gz)        gunzip $archive      ;;
				*.tar)       tar xvf $archive     ;;
				*.tbz2)      tar xvjf $archive    ;;
				*.tgz)       tar xvzf $archive    ;;
				*.zip)       unzip $archive       ;;
				*.Z)         uncompress $archive  ;;
				*.7z)        7z x $archive        ;;
				*)           echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

mkdirgo () {
  mkdir -p $1
  cd $1
}

fext() { echo ${1##*.}; }

fname() {  echo ${1%.*}; }

if command -v git &>/dev/null; then
  git config --global merge.conflictStyle diff3
fi

svndiff() { svn diff "$@" | colordiff | less; }

# Any program hooked up
if command -v script &>/dev/null; then
  rt_graph() { ~/dot-files/scripts/rt_graph/rt_graph_hookup.bash "$*"; }
  rt_graph_add() { echo -e "\r\rRTGRAPH add $*" >/dev/udp/localhost/24242; }
  rt_graph_clear() { echo -e "\r\rRTGRAPH clear_graph" >/dev/udp/localhost/24242; }
  rt_graph_add_time() { echo -e "\r\rRTGRAPH add_time ${1} ${2}" >/dev/udp/localhost/24242; }
  rt_graph_set_paused() { echo -e "\r\rRTGRAPH pause_graph ${1}" >/dev/udp/localhost/24242; }
  rt_graph_start() { ~/dot-files/scripts/rt_graph/python_rt_graph.py &>/dev/null & }
else
  echo "rt_graph support missing: need script command" >&2
fi

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\e[01;32m'
export LESS_TERMCAP_md=$'\e[01;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[01;4;31m'

##### Custom Prompt ###############
function __setprompt
{
	local LAST_COMMAND=$? # Must come first!

	# Define colors
	local LIGHTGRAY="\e[0;37m"
	local WHITE="\e[1;37m"
	local BLACK="\e[0;30m"
	local DARKGRAY="\e[1;30m"
	local RED="\e[1;31m"
	local LIGHTRED="\e[0;31m"
	local GREEN="\e[0;32m"
	local LIGHTGREEN="\e[1;32m"
	local BROWN="\e[0;33m"
	local YELLOW="\e[1;33m"
	local BLUE="\e[1;34m"
	local LIGHTBLUE="\e[0;34m"
	local MAGENTA="\e[0;35m"
	local LIGHTMAGENTA="\e[1;35m"
	local CYAN="\e[0;36m"
	local LIGHTCYAN="\e[1;36m"
	local NOCOLOR="\e[0m"

	# Show error exit code if there is one
	if [[ $LAST_COMMAND != 0 ]]; then
		PS1="\[${LIGHTRED}\]?"
	else
		PS1="\[${LIGHTGREEN}\]?"
	fi

	# Current time
	PS1+="\[${CYAN}\][\A]"

  # Current battery
  if battery 2>&1 > /dev/null ; then
    PS1+=" \[${LIGHTRED}\]{$(battery | awk '{print $2}')}";
  fi

	# Current directory
	PS1+=" \[${DARKGRAY}\](\[${BROWN}\]\w\[${DARKGRAY}\])"

	# Git branch
	local git_branch="$(git branch --show-current 2> /dev/null)"
	if [ $git_branch ]; then
		PS1+=" \[${DARKGRAY}\](\[${CYAN}\]${git_branch}\[${DARKGRAY}\])"
	fi

	# Skip to the next line
	PS1+="\n"

	if [[ $EUID -ne 0 ]]; then
		PS1+="\[${LIGHTBLUE}\]\$\[${NOCOLOR}\] " # Normal user
	else
		PS1+="\[${LIGHTRED}\]\#\[${NOCOLOR}\] " # Root user
	fi

	# PS2 is used to continue a command using the \ character
	PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Select a number: '

	# PS4 is used for tracing a script in debug mode
	PS4='\[${DARKGRAY}\]+\[${NOCOLOR}\] '
}

# test for color support and enable colored prompt if possible
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  PROMPT_COMMAND="__setprompt;$PROMPT_COMMAND"
else
  PS1='[\A]\u:\w \$ '
fi

