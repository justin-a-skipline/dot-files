MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --warn-undefined-variables

.DEFAULT_GOAL := all

CROSS_COMPILE ?=
BUILD_DIR ?= build-writer
CFLAGS ?=
LDFLAGS ?=
DEBUG ?= Y

# Put cross compile specified compilation artifacts into
# separate folder by detecting if CROSS_COMPILE variable
# is empty (empty string after comma)
ifneq ($(CROSS_COMPILE),)
ARTIFACT_DIR = $(BUILD_DIR)/$(CROSS_COMPILE)
else
ARTIFACT_DIR = $(BUILD_DIR)/native
endif

# Source files go here
WRITER_SOURCES = \
			assignments/assignment2/writer.c

# Include directories go here
WRITER_INC = \
			assignments/assignment2/

ENHANCED_WARNINGS += \
			-Wnull-dereference \
			-Wstrict-aliasing=3 \
			-Wduplicated-cond \
			-Wtype-limits \
			-Wsign-compare \
			-Waggressive-loop-optimizations \
			-Wmissing-field-initializers \
			-Wcast-align \
			-Wpointer-arith \
			-Wcast-qual \
			-Wimplicit-fallthrough=2

_CFLAGS = \
			-Wall -Wextra -ggdb3 \
			-fno-common \
			-ffunction-sections \
			-fdata-sections \
			$(ENHANCED_WARNINGS)

_LDFLAGS = -Wl,--gc-sections

ifeq ($(DEBUG),Y) # Debug specific options go here
	# Set up ASAN options
_CFLAGS +=  -fsanitize=address \
						-fno-omit-frame-pointer \
						-fsanitize-address-use-after-scope
_LDFLAGS += -fsanitize=address
# Create C file to be compiled and linked into application
# with default asan options. (See ASAN documentation)
WRITER_SOURCES += $(ARTIFACT_DIR)/asan_default_options.c
$(ARTIFACT_DIR)/asan_default_options.c: $(MAKEFILE_LIST)
	@mkdir -p $(@D)
	@echo 'const char *__asan_default_options() { \
		return "verbosity=1:strict_string_checks=1:detect_stack_use_after_return=1:check_initialization_order=1:strict_init_order=1"; \
	}' > $@

# Set up Undefined Behavior Sanitizer
_CFLAGS += -fsanitize=undefined \
					 -fsanitize=bounds-strict \
					 -fstack-protector-strong
_LDFLAGS += -fsanitize=undefined
else # Release specific options go here
endif

# Insert command line flags last so they override
_CFLAGS += $(CFLAGS)
_LDFLAGS += $(LDFLAGS)

WRITER_OBJECTS = $(foreach src, $(WRITER_SOURCES), $(ARTIFACT_DIR)/$(basename $(src)).o)

all: writer

# Clean will delete all build files, for all configurations within
# the build directory.
.PHONY: clean
clean:
	@rm -rf --preserve-root $(BUILD_DIR)

# Using a recursive make invocation here allows the output artifact
# rule to match (eg. $(ARTIFACT_DIR)/my/output/file) so that the
# outputs of commands can be put into their own directories like
# $(BUILD_DIR)/native or $(BUILD_DIR)/$(CROSS_COMPILE).
.PHONY: writer
writer:
	@$(MAKE) --no-print-directory $(ARTIFACT_DIR)/$@

# This is the rule for creating the final binary. It depends on
# the writer objects
$(ARTIFACT_DIR)/writer: $(WRITER_OBJECTS)
	@mkdir -p $(@D)
	@$(CROSS_COMPILE)gcc $(_LDFLAGS) $^ -o $@

# This rule matches all object files that need to be created and that
# match a ".c" file.
$(ARTIFACT_DIR)/%.o: %.c $(MAKEFILE_LIST)
	@mkdir -p $(@D)
	@echo "CC        $@"
	@$(CROSS_COMPILE)gcc $(_CFLAGS) $(foreach path, $(WRITER_INC), -I$(path)) -c $< -o $@
