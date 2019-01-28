####### environment variables
export EDITOR='vim'
export PAGER='less'
export LSCOLORS="Gxfxcxdxbxegedabagacad"
export LS_COLORS='no=00:fi=00:di=1;44:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:ow=1;44'

####### vi-mode bindings
bindkey -v
bindkey 'jk' vi-cmd-mode
bindkey '^r' history-incremental-search-backward
bindkey ' ' magic-space

###### Shell Settings
 # Interpret non-valid commands that are directory names as a cd to that directory
setopt autocd

 # Automatically do pushd when cding and don't make duplicated pushd entries
setopt autopushd pushdignoredups

# Print job notifications in the long format by default
setopt long_list_jobs

# comments work in interactive shell '#'
setopt interactivecomments

####### Prompt
autoload -U colors && colors
setopt prompt_subst
function zle-line-init zle-keymap-select {
    VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]%  %{$reset_color%}"
    local vim_mode='${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/}'
    local ret_status="%(?:%{$fg_bold[green]%}?:%{$fg_bold[red]%}?)"
    EPS1='${ret_status} %{$fg[cyan]%}%c %{$fg[magenta]%}%#%{$reset_color%} '
    PROMPT="${vim_mode}$EPS1"
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# Use prepackaged prompts instead
# `prompt -l` lists the prompts
#autoload -U promptinit
#promptinit
#prompt adam2


####### aliases
alias ls='ls --color=auto'

alias pdfmerge='gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages -dCompressFonts=true -r150 -sOutputFile=gsout.pdf'

alias battery='upower -i /org/freedesktop/UPower/devices/battery_BAT0'

alias clbin="curl -F 'clbin=<-' https://clbin.com"

if [ -x "$(command -v rg)" ]; then
  alias rg='rg --no-messages --vimgrep --max-filesize 5M --type-add work:include:cpp,c,asm --type-add work:\*.s43 --type-add zig:\*.zig'
elif [ -x "$(command -v ripgrep.rg)" ]; then
  alias rg='ripgrep.rg --no-messages --vimgrep --max-filesize 5M --type-add work:include:cpp,c,asm --type-add work:\*.s43 --type-add zig:\*.zig'
fi
  
  

####### shell completion
autoload -U compinit
compinit

unsetopt menu_complete
#unsetopt flowcontrol
setopt auto_menu
setopt complete_in_word
setopt always_to_end
setopt list_packed

zstyle ':completion:*:*:*:*:*' menu select

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR

