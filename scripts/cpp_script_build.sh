# This is a /bin/sh script which runs make
# To use it, include the following lines at the top of your main c/cpp file
# or copy the script directly into the block.
# #if 0
# source ~/dot-files/scripts/cpp_script_build.sh
# #endif
# EXTRA_FILES can be defined in that block to add multiple files to the compilation
TARGET=/tmp/$(basename $0).run

mkdir -p $(dirname $TARGET) || { echo "Failed to create $TARGET"; exit 1; }

make -f - <<EOF
FILES = $0 $EXTRA_FILES

WARNINGS=-Wall -Wextra -Wformat -Wcast-align -Wcast-qual -Warray-compare -Wpointer-arith
CFLAGS = -ggdb3 -std=gnu11 -fsanitize=undefined
CPPFLAGS = -ggdb3 -std=gnu++11 -fsanitize=undefined
LDFLAGS = -fsanitize=undefined
LIBS = -lubsan
TARGET = $TARGET
OBJECTS := \$(FILES:.c=.o)
OBJECTS := \$(OBJECTS:.cpp=.o)

all: \$(TARGET)
\$(TARGET): \$(OBJECTS)
	g++ -o \$@ \$(OBJECTS) \$(LDFLAGS) -Wl,--start-group \$(LIBS) -Wl,--end-group
%.o: %.c
	gcc -c \$< -o \$@ \$(CFLAGS)
%.o: %.cpp
	g++ -c \$< -o \$@ \$(CPPFLAGS)

EOF

if test $? -ne 0 || ! $TARGET; then
  echo "Failed to build/run $TARGET"
exit 1
fi

exit; # exit before reaching c/cpp code below
