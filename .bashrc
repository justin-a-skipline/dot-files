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

PROMPT_COMMAND=""

stty -ixon
##### VIM Settings ##############
set -o vi
bind -f "${HOME}/dot-files/.inputrc"

export EDITOR="vim"
export VISUAL="vim"
alias vi='vim'

##### History Settings ##########
HISTCONTROL='erasedups:ignoreboth'
HISTSIZE=100000
HISTFILESIZE=100000
HISTIGNORE='?:??'
shopt -s histappend histverify
PROMPT_COMMAND+='history -a;history -c;history -r'

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

  if [ -d /usr/local/share/bash-completion/completions ]; then
    for file in /usr/local/share/bash-completion/completions/*; do
      source "$file"
    done
  fi
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

red_msg()
{
	echo -en "\e[0;31m"
	echo "$@"
	echo -en "\e[0m"
}

encode_video_to_x265()
{
  if [ $# -lt 1 ]; then
    return 1;
  fi

  file="$1"
  echo "Processing $file to $file.mov"
  ffmpeg -y -i "$file" -codec:v libx265 -crf 30 -threads 7 "$file.mov" &> /dev/null
  echo -e "\tOld size: $(du -h "$file" | cut -f1)\tNew size: $(du -h "$file.mov" | cut -f1)"
}

basic_encrypt_file_stdin()
{
  openssl aes-256-cbc -salt
}

basic_decrypt_file_stdin()
{
  openssl aes-256-cbc -salt -d
}

_gl()
{
	if [ $# -eq 1 ]; then
		commit_argument="$1" # Use passed in argument (eg. origin/main.. to select b/t origin/main to HEAD)
	else
		commit_argument="HEAD"
	fi

	stderr_output_prog="cat"
	if command -v lolcat &>/dev/null; then
		stderr_output_prog="lolcat"
	fi
	# Mirror stdout of this subshell to stderr using tee so you can
	# see which sha was selected
	( set -o pipefail; git log --oneline --decorate --color "$commit_argument" | fzf --height=50% --ansi --multi | cut -d' ' -f1 ) | tee >("$stderr_output_prog" >&2)
}

git_fzf_log_get_sha()
{
	declare -n ret=$1
	command -v fzf > /dev/null || { echo "Install fzf to use"; return 1; }
	local commit_argument="HEAD"

	if [ $# -eq 2 ]; then
		commit_argument="$2" # Use passed in argument (eg. origin/main.. to slect b/t origin/main to HEAD)
	fi

	ret=$(set -o pipefail; git log --oneline --decorate --color "$commit_argument" | fzf --height=50% --ansi | cut -d' ' -f1) || return 1
}

git_fzf_log_get_multiple_sha()
{
	declare -n ret=$1
	command -v fzf > /dev/null || { echo "Install fzf to use"; return 1; }
	local commit_argument="HEAD"

	if [ $# -eq 2 ]; then
		commit_argument="$2" # Use passed in argument (eg. origin/main.. to slect b/t origin/main to HEAD)
	fi

	ret=$(set -o pipefail; git log --oneline --decorate --color "$commit_argument" | fzf --height=50% --ansi --multi | cut -d' ' -f1) || return 1
}

gc_fixup()
{
	sha="$(_gl "$@")"
	echo git commit --fixup "$sha"
	git commit --fixup "$sha"
}

gc_rebase()
{
	sha="$(_gl "$@")"
	echo git rebase -i "$sha"
	git rebase -i "$sha"
}

gc_cherrypick()
{
	sha="$(_gl "$@")"
	echo git cherry-pick "$sha"
	git cherry-pick "$sha"
}
#complete -C 'makelist() { for branch in $(git for-each-ref --format=\"%\(refname:short\)\"); do echo "$branch"; done; }; filter() { makelist | sort -u; }; filter' gc_cherrypick

fuzzy_history()
{
	history | fzf --tac | tr -s ' ' | cut -d' ' -f3-
}

do_fuzzy_history()
{
	local cmd="$(fuzzy_history)"
	$cmd
}

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

trim_whitespace() { sed -e 's/[ \t]\+//' -e 's/[ \t]+$//'; }

fext() { echo ${1##*.}; }

fname() {  echo ${1%.*}; }

cp_rename() {
  test $# -ge 2 || return 1
  cp "$1" "$2".$(fext "$1")
}

if command -v git &>/dev/null; then
  git config --global merge.conflictStyle diff3
fi

valgdb() {
  if [ $# -eq 0 -o "$1" = "--help" ]; then
  cat << "EOF"
  usage: valgdb [valgrind options] <path/to/executable>
EOF
  return 1
  fi

  valgrind --vgdb-error=0 "$@" &
  valpid=$!
  gdb -ex "target remote | vgdb --pid=$!" "${!#}"
  kill -9 "$valpid"
}

public_ip()
{
	curl -s https://checkip.amazonaws.com
}

svndiff() { svn diff "$@" | colordiff | less -x1,5; }
svnbranchlog()
{
  if [ $# -ne 0 -a "$1" = "--help" ]; then
  cat << "EOF"
  usage: svnbranchlog [option]

  options:
  --commit-wise-branch Default, all commits since branch creation across all externals
  --total-branch       All changes since branch creation across all externals
EOF
  fi

  cat > ~/.git-svn-diff.bash << "EOF"
#!/usr/bin/env bash
git --no-pager diff --color --color-moved=dimmed-zebra --histogram -W --no-index $6 $7
EOF
  chmod +x ~/.git-svn-diff.bash
  local -r branch_url=$(svn info | sed -E -e '/^Relative URL/!d' -e 's/Relative URL: //')
  local -r branch_rel_path=$(echo $branch_url | sed -E -e 's/\^\///')
  local -r initial_branch_revision=$(svn log -r1:HEAD --stop-on-copy -l1 ^/ "$branch_rel_path" | awk 'NR==2 {print $1}' | sed -e 's/r//')
  local -a external_list_url_array=(
  $(svn propget svn:externals -R | sed -E -e 's/^[^^]*//' -e '/^\^/!d' | awk '{$NF=""; print}')
  )
  local -a external_list_rel_path_array=(
  $(echo ${external_list_url_array[*]} | sed -E -e 's/\^\///g')
  )

  let local -r first_revision_after_branch_creation=$initial_branch_revision+1

  if [ $# -eq 0 -o "$1" = "--commit-wise-branch" ]; then
    svn log "-r$first_revision_after_branch_creation:HEAD" --diff --diff-cmd ~/.git-svn-diff.bash --stop-on-copy ^/ "$branch_rel_path" ${external_list_rel_path_array[*]}
  elif [ "$1" = "--total-branch" ]; then
    svn diff --no-diff-deleted --no-diff-added --show-copies-as-adds --verbose -r "$initial_branch_revision:HEAD" --diff-cmd ~/.git-svn-diff.bash "$branch_url" ${external_list_url_array[*]}
  fi
}

# Any program hooked up
if command -v script &>/dev/null; then
  mkfifo ~/dot-files/scripts/rt_graph/rt_graph.fifo &> /dev/null || :
  rt_graph() { ~/dot-files/scripts/rt_graph/rt_graph_hookup.bash "$*"; }
  rt_graph_add() { echo -e "\r\rRTGRAPH add $*" >~/dot-files/scripts/rt_graph/rt_graph.fifo; }
  rt_graph_clear() { echo -e "\r\rRTGRAPH clear_graph" >~/dot-files/scripts/rt_graph/rt_graph.fifo; }
  rt_graph_add_time() { echo -e "\r\rRTGRAPH add_time ${1} ${2}" >~/dot-files/scripts/rt_graph/rt_graph.fifo; }
  rt_graph_set_paused() { echo -e "\r\rRTGRAPH pause_graph ${1}" >~/dot-files/scripts/rt_graph/rt_graph.fifo; }
  rt_graph_start() { ~/dot-files/scripts/rt_graph/python_rt_graph.py &>/dev/null & }
  rt_graph_set_title() { echo -e "\r\rRTGRAPH set_title ${1}" >~/dot-files/scripts/rt_graph/rt_graph.fifo; }
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

	PS1=""

	# Define colors
	local LIGHTGRAY=""
	local WHITE=""
	local BLACK=""
	local DARKGRAY=""
	local RED=""
	local LIGHTRED=""
	local GREEN=""
	local LIGHTGREEN=""
	local BROWN=""
	local YELLOW=""
	local BLUE=""
	local LIGHTBLUE=""
	local MAGENTA=""
	local LIGHTMAGENTA=""
	local CYAN=""
	local LIGHTCYAN=""
	local NOCOLOR=""
	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
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
	else
		# add separator to commands since color doesn't help distinguish
		PS1+=$(for ((i=0;i<${COLUMNS};i++)); do echo -n "-"; done;)
	fi

	# Show colored error exit code
	if [[ $LAST_COMMAND != 0 ]]; then
		PS1+="\[${LIGHTRED}\]"
	else
		PS1+="\[${LIGHTGREEN}\]"
	fi
	PS1+="[${LAST_COMMAND}]"

	# Current time
	PS1+="\[${CYAN}\][\A]"

	# Current directory
	PS1+=" \[${DARKGRAY}\](\[${BROWN}\]\w\[${DARKGRAY}\])"

	# Git branch
	local git_branch="$(git branch --show-current 2> /dev/null)"
	local svn_url="$(svn info 2>/dev/null | grep "Relative URL: " | cut -d' ' -f3-)"
	if [ $git_branch ]; then
		PS1+=" \[${DARKGRAY}\](\[${CYAN}\]${git_branch}\[${DARKGRAY}\])"
	elif [ $svn_url ]; then
		PS1+=" \[${DARKGRAY}\](\[${CYAN}\]${svn_url}\[${DARKGRAY}\])"
	fi

	if [ -n "$VIRTUAL_ENV" ]; then
		PS1+=" \[${DARKGRAY}\](\[${LIGHTMAGENTA}\]venv:${VIRTUAL_ENV}\[${DARKGRAY}\])"
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

PROMPT_COMMAND="__setprompt;$PROMPT_COMMAND"

######## WORK SECTION #########

gc_build()
{
	(
	export PATH=${HOME}/qt_versions/5.15.2/gcc_64/bin/:"$PATH"
	mkdir -p build && cd build/ && qmake .. CONFIG+=debug && make -j8
	) 2>&1 > /dev/null | sed -e 's;^../../;;'
}
gc_static_analyze()
{
	GC_STATIC_ANALYZER="clazy --standalone"
#	GC_STATIC_ANALYZER="clang-tidy"
	(
	export CLAZY_HEADER_FILTER="\./"
	jq '.[].directory+"/"+.[].file'  build/compile_commands.json |
		sort | uniq |
		xargs "$GC_STATIC_ANALYZER" -p build \
			--extra-arg="-Wno-inconsistent-missing-override" \
			--extra-arg="-Wno-clazy-connect-by-name" \
			--export-fixes="$(readlink -f build/fixes.yaml)"
	)
}
gc_hw_build()
{
	if ! ( grep 'BR2_DEFCONFIG' "${HOME}/workspace/buildroot-hdvo/.config" | grep 'zynq_hdvo318_defconfig' ); then
		red_msg "Must use correct defconfig: make zynq_hdvo318_defconfig"
		return 1
	fi
	(
	mkdir -p hw-build && cd hw-build/ && "${HOME}/workspace/buildroot-hdvo/output/host/bin/qmake" .. && make -j8
	) 2>&1 > /dev/null
}

canutils_build()
{
	(
	export PATH=${HOME}/qt_versions/5.15.2/gcc_64/bin/:"$PATH"
	# -k flag keeps going when CANDisplay fails to build correctly
	# Building with qt4 is desired now because stax viewer has janky colors at the moment with qt5
	mkdir -p build && cd build/ && qmake .. CONFIG+=debug && bear --append make -j8 -k
	) 2>&1 > /dev/null | sed -e 's;^../../;;'
}

ust_build()
{
	(
	export PATH=${HOME}/qt_versions/5.15.2/gcc_64/bin/:"$PATH"
	mkdir -p build && cd build/ && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && make -j8
	) 2>&1 > /dev/null
}

ust_hw_build()
{
	(
	export UST_BUILDROOT_DIR="${HOME}/workspace/buildroot-ust20"
	mkdir -p build/build-hw && cd build/build-hw/ && "$UST_BUILDROOT_DIR/output/host/bin/cmake" -Wno-dev -DCMAKE_TOOLCHAIN_FILE=../../ust20_toolchain.cmake -DUST_BUILDROOT_DIR:PATH="$UST_BUILDROOT_DIR" ../.. && make -j8
	) 2>&1 > /dev/null
	# See script.sh in ~/workspace/ust-update/update-example
	# This script is what runs, basically copied to each update
	# different systems may need to do different things.
	# Pass the list of files to the mkupdate
	# Dan T is using _Release/ from CoreSkipper, confirm if that is ok
#(ins)$ cd ~/workspace/buildroot-ust20/board/skipline/ust20_updateroot/UpdateCreator/
#make_update.sh
#bash ./make_update.sh ~/workspace/ust-update/whiteline/*
# makes output/update.bin

# https://git.skip-line.com/dan_sl/u-st20 is where the setups for a brand new
#    ust20 setup are
# Need new folder for safety mark or whoever in skiprepo
}

pigeon_hw_build()
{
	(
	export PATH=/opt/swi/y25-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/:"$PATH"
	mkdir -p build && cd build/ && /opt/swi/y25-ext/sysroots/x86_64-pokysdk-linux/usr/bin/qmake .. && make -j8
	) 2>&1 > /dev/null
}

gc_system()
{( # subshell so env doesn't leak
		system="${1:?system required eg~/skiprepo/production/systems/GC12_A22311/variants/cellular_hdvo/}"
		# default to root directory, per gc developer setup instructions
		SKLCORE_ROOT="${2:-/}"
		rm -rf --preserve-root "$SKLCORE_ROOT"/data/* "$SKLCORE_ROOT"/factorydefaults/*
		cp "$system"/factorydefaults/*.xml "$SKLCORE_ROOT"/factorydefaults/
		cp "$system"/permissions/permissions.json "$SKLCORE_ROOT"/factorydefaults/
		# Woops! These should be per dev becasue DataTransmit could be generating SRO data on the dev PC.
		cp "$system"/loggingconfig.json "$SKLCORE_ROOT"/factorydefaults/
		cp "$system"/enc_id "$SKLCORE_ROOT"/factorydefaults/

		cp "$system"/DefaultUIConfig.json "$SKLCORE_ROOT"/factorydefaults/
		cp "$system"/PatternConfig.json "$SKLCORE_ROOT"/factorydefaults/
)}

ust_run() {
	(
		export QT_LOGGING_RULE=qt.qml.binding.removal.info=true
		export LD_LIBRARY_PATH=$HOME/qt_versions/5.15.2/gcc_64/lib
		./build/src/ust
	)
}

remote_connect_wait_for_tunnel()
{
	if [ $# -lt 1 ] || [ -z "$1" ]; then
		echo "Pass CVO_xxxx as first param" 1>&2
		return 1
	fi
	local CVO_ID
	CVO_ID="$1"
	mosquitto_pub -h realtime.skip-line.com -p 8883 -u m742r5O599CaV5W -P GQ52Rn5jK97iwQj -t "HDVO/$CVO_ID/REMOTE_CONNECT" -n --capath /etc/ssl/certs || { echo "mosquitto failed"; return 1; }
	echo "do 'ps aux | grep ssh' until a new connection appears"
	echo "then use remote_connect_start_ssh"
	# RT is also a channel (replacing REMOTE_CONNECT) and doesn't require remote connection stuff I think
}
remote_connect_start_ssh()
{
	ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ~/Documents/hdvo_ssh/hdvo_access_key -p 1234 root@localhost
	red_msg "DON'T FORGET TO CLOSE THE REMOTE CONNECTION IN ORG"
}

switch_functions_to_num()
{
	cpp -P -D'DefineSwitchFunction(a,b,c)=__COUNTER__ a' "$HOME/workspace/skipline/projects/common_libs/switches/switch_functions.def" | awk '{ print $1+1 "\t" $2 }'
}

kiwi_build()
{
	#https://github.com/Spec-Rite/Kiwi/wiki/Building#building-kiwi
	(
	mkdir -p build && cd build/ && cmake -DCPU_ONLY=on -DCMAKE_BUILD_TYPE=Debug -DDESKTOP_BUILD=ON .. && make -j8 && make dev_gui -j8
	) 2>&1 > /dev/null
}

kiwi_hw_build()
{
	# Building on the actual target
	#https://github.com/Spec-Rite/Kiwi/wiki/Building#building-kiwi
	(
	mkdir -p build && cd build/ && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/eagleeye_toolchain.cmake -DKIWI_BUILD=ON .. && make -j8
	) 2>&1 > /dev/null
}

kiwi_stream_to_video4()
{
	# This matches the first sampleconfig.json input in the Kiwi repo
	video=/dev/video4
	fakevideonum=7
	if [ $# -lt 1 ]; then
		red_msg "Usage: ${FUNCNAME[0]} <path to image>"
		return 1
	fi

	if [ ! -h "$video" ]; then
		# We have to make a loopback device and then
		# symlink it to /dev/video0 because the Kiwi looks
		# at that device name.
		sudo mv "$video" "$video".bak
		sudo modprobe v4l2loopback video_nr="$fakevideonum"
		sudo ln -s "/dev/video$fakevideonum" "$video"
	fi

	is_image=false
	if file "$1" | grep -E -i "(jpeg|jpg|bmp|png)"; then
		is_image=true
	fi

	# This encodes the image into a loop and streams the raw h264 video
	# to stdout. The second ffmpeg instance grabs it off stdin and sends
	# it to the loopback device. Note that it will fail if the image width
	# and height are not even numbers.
	# We scale the video to the expected dimensions
	if [ "$is_image" = "true" ]; then
		ffmpeg -re -loop 1 -i "$1" -vf "scale=1920:1080" -c:v libx264 -tune stillimage -pix_fmt yuv420p -f rawvideo - | ffmpeg -re -i - -f v4l2 "/dev/video$fakevideonum"
	else
		# Run the input video on a loop
		ffmpeg -re -stream_loop -1 -i "$1" -vf "scale=1920:1080" -c:v libx264 -f v4l2 "/dev/video$fakevideonum"
	fi
}

start_StaxViewer()
{
	~/workspace/skipline/projects/canutils/build/StaxViewer/StaxViewer --truck "$@" &>/dev/null &
}
start_GrinderTester()
{
	~/workspace/skipline/projects/canutils/build/GrinderTester/GrinderTester &>/dev/null &
}
start_CANDisplayV2()
{
	~/workspace/skipline/projects/canutils/build/CANDisplayV2/CANDisplayV2 &>/dev/null &
}
start_BerendsenSim()
{
	~/workspace/skipline/projects/canutils/build/BerendsenSim/BerendsenSim &>/dev/null &
}
start_LaserSimulator()
{
	~/workspace/skipline/projects/canutils/build/LaserSimulator/LaserSimulator &>/dev/null &
}
start_EatonKeypad()
{
	~/workspace/skipline/projects/canutils/build/EatonJ1939KeypadSim/EatonJ1939KeypadSim &>/dev/null &
}
start_EatonOutput()
{
	~/workspace/skipline/projects/canutils/build/EatonJ1939OutputSim/EatonJ1939OutputSim &>/dev/null &
}
start_SupportSimUtil()
{
	python3 ~/workspace/SupportSimUtil/mainwindow.py &>/dev/null &
}
start_BootloaderGUI()
{
	~/workspace/skipline/projects/canutils/build/BootloaderGUI/BootloaderGUI &>/dev/null &
}
start_TruckDesigner()
{
	(cd ~/workspace/skipline/projects/can-cfg && ./build/can-cfg &>/dev/null) &
}
start_MakeSystemUpdate()
{
	(cd ~/workspace/skipline/projects/utils/UpdateCreator && ./make_system_update.sh "$@" && cp ~/Downloads/DL-18UpdateInstructions.pdf ./output/ && xdg-open ./output)
}
start_DeployManualBinaries()
{
	if [ "$#" -lt 1 ]; then
		return 1
	fi

	system_file=$(readlink -f "$1")
	if ! [ -e "$system_file" ]; then
		echo "system file doesn't exist"
		return 1
	fi

	(cd ~/workspace/skipline/projects/skipper && ./systems/select_system.py "$system_file" && ./scripts/eclipse_build.sh Deploy _Deploy . && ./scripts/deployBinaries.py)
}
start_TruckDesignerNoSVN()
{
	(cd ~/workspace/skipline/projects/can-cfg && ./build/can-cfg --svntestonly &>/dev/null) &
}
start_UpdateApollo()
{
	ssh burner@apollo.skip-line.com "cd skiprepo/production/systems && svn up"
}
start_meldSystemFiles()
{
	(
	cd ~/skiprepo/production/systems || return 1
	if ! [ -d "$1" ]; then
		echo "system directory doesn't exist"
		return 1
	fi
	cd "$1" || return 1

	files=( "permissions/permissions.json" "factorydefaults/IOConfig.xml" "factorydefaults/DefaultUIConfig.xml" )

	td_folder="td_variants/logging"
	if ! [ -d "$td_folder" ]; then
		td_folder="td_variants/non_logging"
	fi
	if ! [ -d "$td_folder" ]; then
		echo "no td folder"
	fi

	variants_folder="variants/cellular_hdvo"
	if ! [ -d "$variants_folder" ]; then
		variants_folder="variants/logging"
	fi
	if ! [ -d "$variants_folder" ]; then
		variants_folder="variants/non_logging"
	fi
	if ! [ -d "$variants_folder" ]; then
		echo "no variants folder"
		# Actually just print list of file pairs to diff, then make outer function that calls meld with
		# --diff option repeatedly. Then each new call to these functions will open a new meld instance.
	fi

	for file in "${files[@]}"; do
		echo meld "$td_folder/$file" "$variants_folder/$file" -n
		meld "$td_folder/$file" "$variants_folder/$file" -n &>/dev/null &
	done

	start_meldManualAndTD "$1"

	)
}
start_meldManualAndTD()
{
	(
	if ! [ "$#" -eq 1 ]; then
		red_msg "Pass system name eg systems/sc12_blah_MANUAL or sc12_blah"
		return 1
	fi

	local sanitized_input;
	sanitized_input=$(basename "${1%%/}");
	local base_system="${sanitized_input%%_MANUAL.h}"
	local maybe_manual_system="${base_system}_MANUAL"

	local manual_system_file_name="${maybe_manual_system}.h"

	local skipper_systems_folder="$HOME/workspace/skipline/projects/skipper/systems"
	local systems_folder="$HOME/skiprepo/production/systems"

	if ! [ -d "$systems_folder/$base_system" ]; then
		red_msg "$systems_folder/$base_system does not exist"
		return 1
	fi
	if ! [ -f "$skipper_systems_folder/$manual_system_file_name" ]; then
		red_msg "$skipper_systems_folder/$manual_system_file_name does not exist"
	fi

	echo meld "$systems_folder/$base_system/system.h" "$skipper_systems_folder/$manual_system_file_name" -n
	meld "$systems_folder/$base_system/system.h" "$skipper_systems_folder/$manual_system_file_name" -n &>/dev/null &

	while IFS= read -r -d '' switchfile; do
		local filename
		filename=$(basename "$switchfile")
		echo meld "$switchfile" "$systems_folder/${base_system}_MANUAL/$filename" -n
		meld "$switchfile" "$systems_folder/${base_system}_MANUAL/$filename" -n &>/dev/null &
	done < <(find "$systems_folder/$base_system/" -type f -name "*Switch.xml" -print0)
	)
}

start_RebuildTDAndGC()
{
	(cd ~/workspace/skipline/projects/can-cfg && touch can-cfg.qrc && scripts/command_line_dev_build --quiet)
	(cd ~/workspace/skipline/projects/GlassCockpit && scripts/command_line_dev_build --release-pc --quiet)
}

start_DeployHDVO()
{
	if [ $# -lt 1 ]; then
		return 1
	fi
	local folder_path
	folder_path="$(readlink -f "$1")"
	if ! [ -d "$folder_path" ]; then
		red_msg "$folder_path is not a valid directory"
		return 1
	fi

	( cd "$folder_path" && ~/workspace/skipline/projects/GlassCockpit/scripts/deployHDVOscript/deployHDVO.py "$(basename "$folder_path")" )
}

start_MakeSystemManual()
{
	if [ $# -lt 1 ]; then
		return 1
	fi
	local folder_path
	folder_path="$(readlink -f "$1")"
	if ! [ -d "$folder_path" ]; then
		red_msg "$folder_path is not a valid directory"
		return 1
	fi

	( cd ~/workspace/skipline/projects/skipper && ./scripts/make_system_manual.sh "$(basename "$folder_path")" )
}

start_DeployStandaloneHDVO()
{
	( cd ~/hdvo-318/code/hdvo-318/scripts/production && ./hdvo_config_deploy.py )
}

start_ProgramSwc-1312()
{
	avrdude -pc128 -cavrisp2 -Pusb -B6 -F -u -Uflash:w:avr-cbl/STANDALONE_SWITCH_BOX/avr-cbl.hex:a -Ulfuse:w:0xFF:m -Uhfuse:w:0xD0:m -Uefuse:w:0xF5:m
}

start_sgpt()
{
	sgpt --model 'gpt-4' "$@"
}

example_find()
{
	# handles newlines, spaces, etc
	while IFS= read -r -d '' file; do
		echo "$file"
	done < <(find "$dir" -type f \( -name "*.bin" -o -name "*Wiring Sheet.pdf" \) -print0)
}

start_search_systems_for_features()
{
	while IFS= read -r -d '' file; do
		local llama_info
		llama_info=$(jq -e 'recurse | select(.materialPressureOutput? == "Adaptive Paint Pressure Control")' "$file")
		if $?; then
			:
			# This isn't working yet, want to look at num pump inputs per color that matches llama being enabled above
#			local pumpInputsForColor
#			pumpInputsForColor=$(jq -e "recurse | select(numPumpInputs.$(echo "$llama_info" | jq 'select(.color)').materialPressureOutput? == "Adaptive Paint Pressure Control")" "$file")
		fi
	done < <(find "$HOME/skiprepo/production/systems" -type f -name "*.truck" -print0)
}

helper_yes_no_dialog()
{
	local prompt="Continue?"
	if [ $# -gt 0 ]; then
		prompt="$1"
	fi
	local answer="N"
	read -r -p "$(echo -e $prompt) (Yy/Nn): " answer
	case "$answer" in
		Y|y)
			;;
		*) return 1;
	esac
}

svncommit()
{
	command_options=("$@")
	for (( i=0; i<${#command_options[@]}; i++ )); do
		if [[ ${command_options[i]} == "-m" ]]; then
			unset "command_options[i]"
			unset "command_options[i+1]"
		fi
	done

	svn status "${command_options[@]}"
	local answer="N"
	helper_yes_no_dialog "Do you want to commit these files?" || return 1;

	svn commit "$@"
}

start_send_file_to_printer()
{
	local prompt="Is this file list correct?\n"
	for file in "$@"; do
		prompt+="$file\n"
	done
	helper_yes_no_dialog "$prompt" || return 1;
	for file in "$@"; do
		echo "put \"$file\"" | tee | sftp -b - -i ~/.cancfg/id_rsa_cancfg_apollo cancfg@printstation.skip-line.com
	done
}

######## END WORK SECTION #########
