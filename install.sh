#!/bin/sh

cat << EOF > .screenrc
source ~/dot-files/.screenrc
EOF

cat << EOF > .vimrc
set rtp+=~/dot-files/.vim
source ~/dot-files/.vim/vimrc
EOF

cat << EOF > .bashrc
source ~/dot-files/.bashrc
EOF

cat << EOF > .gdbinit
source ~/dot-files/gdb/gdbinit-pure.gdb
EOF
