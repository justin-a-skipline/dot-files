# This is a /bin/sh script which runs make
# To use it, include the following lines at the top of your main c/cpp file
# or copy the script directly into the block.
# #if 0
# source ~/dot-files/scripts/cpp_script_build.sh
# #endif
# EXTRA_FILES can be defined in that block to add multiple files to the compilation
cd $(realpath $(dirname $0)) || { echo "Failed to cd to directory"; exit 1; }
TARGET="$(realpath $0.run)"

mkdir -p $(dirname $TARGET) || { echo "Failed to create $TARGET"; exit 1; }

make -j$(nproc) -f - <<EOF
.DEFAULT_GOAL := all
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory

FILES = $0 $EXTRA_FILES
INCLUDE_DIRS = .

WARNINGS=-Wall -Wextra -Wformat -Wcast-align -Wcast-qual -Warray-compare -Wpointer-arith
CFLAGS = -ggdb3 -std=gnu11 -fsanitize=undefined \$(addprefix -I, \$(INCLUDE_DIRS))
CPPFLAGS = -ggdb3 -std=gnu++11 -fsanitize=undefined \$(addprefix -I, \$(INCLUDE_DIRS))
LDFLAGS = -fsanitize=undefined
LIBS = -lubsan
TARGET = $TARGET
OBJECTS := \$(FILES:.c=.o)
OBJECTS := \$(OBJECTS:.cpp=.o)
-include \$(OBJECTS:.o=.d)

all: \$(TARGET)
\$(TARGET): \$(OBJECTS)
	g++ -o \$@ \$(OBJECTS) \$(LDFLAGS) -Wl,--start-group \$(LIBS) -Wl,--end-group
%.o: %.c
	gcc -c \$< -o \$@ -MMD -MP \$(CFLAGS)
%.o: %.cpp
	g++ -c \$< -o \$@ -MMD -MP \$(CPPFLAGS)

EOF

if test $? -ne 0 || ! $TARGET; then
  echo "Failed to build/run $TARGET"
exit 1
fi

exit; # exit before reaching c/cpp code below
