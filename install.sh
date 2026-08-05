#!/bin/sh
# Put the dotfiles in place. Everything real lives in ~/dot-files -- this only
# creates the symlinks, the stub rc files, and the directories vim needs.

set -e

DOT_FILES="$HOME/dot-files"

Link()
{
  target="$1"
  link_name="$2"

  if [ -L "$link_name" ] || [ ! -e "$link_name" ]; then
    ln -sfn "$target" "$link_name"
    echo "linked $link_name -> $target"
  else
    echo "SKIPPED $link_name: already exists and is not a symlink" >&2
  fi
}

# vim finds ~/.vim/vimrc on its own, so there is no ~/.vimrc stub. A leftover one
# would take priority over it, so report it rather than deleting it.
if [ -e "$HOME/.vimrc" ]; then
  echo "WARNING: $HOME/.vimrc exists and overrides ~/.vim/vimrc -- remove it" >&2
fi

Link "$DOT_FILES/vim" "$HOME/.vim"

# Neovim needs nothing of its own: point its init.vim straight at the vimrc, which
# guards the differences with has('nvim').
mkdir -p "$HOME/.config/nvim"
Link "$DOT_FILES/vim/vimrc" "$HOME/.config/nvim/init.vim"

# vim writes no undo file at all when 'undodir' does not exist, and neovim's undo
# format is not interchangeable with vim's, hence two directories.
mkdir -p "$DOT_FILES/vim/undo" "$DOT_FILES/vim/undo-nvim"

cat << EOF > ~/.screenrc
source ~/dot-files/.screenrc
EOF

cat << EOF > ~/.bashrc
source ~/dot-files/.bashrc
EOF

cat << EOF > ~/.gdbinit
source ~/dot-files/gdb/gdbinit-pure.gdb
EOF

cat << EOF > ~/.inputrc
\$include ~/dot-files/.inputrc
EOF

ExtraInstructions()
{
  cat << EOF

  Install these before using the vimrc:
    universal-ctags
    ripgrep
    jq             mylint.vim reads compile_commands.json with it

  Then start vim and run :PlugInstall

  Optional:
    neovim         shares the same vimrc through ~/.config/nvim/init.vim
EOF
}

ExtraInstructions
