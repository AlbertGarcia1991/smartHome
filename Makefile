# Custom funtions
addprefixwithspace = $(addprefix $(1) , $(2))

# Directories
TOOLS_DIR = ${TOOLS_PATH}
DEV_TOOLS_DIR = $(TOOLS_DIR)
MSPGCC_ROOT_DIR = $(DEV_TOOLS_DIR)/msp430-gcc
MSPGCC_BIN_DIR = $(MSPGCC_ROOT_DIR)/bin
MSPGCC_INCLUDE_DIR = $(MSPGCC_ROOT_DIR)/include
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj
BIN_DIR = $(BUILD_DIR)/bin
TI_CSS_DIR = $(DEV_TOOLS_DIR)/ccs1271/ccs/ccs_base/DebugServer
DEBUG_BIN_DIR = $(TI_CSS_DIR)/bin
DEBUG_DRIVERS_DIR = $(TI_CSS_DIR)/drivers
CPPCHECK = cppcheck
CLANG_FMT = clang-format-12
LIB_DIRS = $(MSPGCC_INCLUDE_DIR)
INCLUDE_DIRS = $(MSPGCC_INCLUDE_DIR) ./src ./external ./external/printf

# Static Analysis
## Don't check the msp430 helper headers (they have a LOT of ifdefs)
CPPCHECK_INCLUDES = ./src ./
IGNORE_FILES_FORMAT_CPPCHECK = \
	external/printf/printf.h \
	external/printf/printf.c
SOURCES_FORMAT_CPPCHECK = $(filter-out $(IGNORE_FILES_FORMAT_CPPCHECK),$(SOURCES))
HEADERS_FORMAT = $(filter-out $(IGNORE_FILES_FORMAT_CPPCHECK),$(HEADERS))
CPPCHECK_FLAGS = \
	--quiet --enable=all --error-exitcode=1 \
	--inline-suppr \
	--suppress=missingIncludeSystem \
	--suppress=unmatchedSuppression \
	--suppress=unusedFunction \
	$(addprefix -I,$(CPPCHECK_INCLUDES)) \

# Toolchain
CC = $(MSPGCC_BIN_DIR)/msp430-elf-gcc
DEBUG = LD_LIBRARY_PATH=$(DEBUG_DRIVERS_DIR) $(DEBUG_BIN_DIR)/mspdebug

# HW Target
MCU = msp430g2553

# Compiler/Linker flags
WFLAGS = -Wall -Wextra -Werror -Wshadow
CFLAGS = -mmcu=$(MCU) $(WFLAGS) $(call addprefixwithspace, -I, $(INCLUDE_DIRS)) -Og -g
LDFLAGS = -mmcu=$(MCU) $(call addprefixwithspace, -L, $(LIB_DIRS))

# Files
TARGET = $(BIN_DIR)/main
SOURCES = src/main.c # .c source files

OBJECT_NAMES = $(SOURCES:.c=.o)
OBJECTS = $(patsubst %, $(OBJ_DIR)/%, $(OBJECT_NAMES))

## Linking
$(TARGET): $(OBJECTS)
	@echo "Linking..."
	@mkdir -p $(dir $@)
	$(CC) $(LDFLAGS) $(addprefix $(OBJ_DIR)/, $(notdir $^)) -o $@
	@echo "Linked $(addprefix $(OBJ_DIR)/, $(notdir $^)) -> $@"

## Compiling
$(OBJ_DIR)/%.o: %.c
	@echo "Building $^ -> $@..."
	@mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) -c -o $(addprefix $(OBJ_DIR)/, $(notdir $@)) $^
	@echo "Built $^ -> $(addprefix $(OBJ_DIR)/, $(notdir $@))"

# $^ -> Prerequisite(s)
# $@ -> Target(s)

# Phonies
.PHONY: all clean flash cppcheck format

## Build all
all: $(TARGET)

## Clean
clean:
	@rm -f -r $(BUILD_DIR)
	@echo "Build removed" 

## Flash (and build if not done yet)
flash: $(TARGET)
	$(DEBUG) tilib "prog $(TARGET)"
	@echo "Flashing..."

## CppCheck
cppcheck:
	@$(CPPCHECK) $(CPPCHECK_FLAGS) $(SOURCES_FORMAT_CPPCHECK)

## Clang C/C++ code formater
format:
	@$(CLANG_FMT) -i $(SOURCES_FORMAT_CPPCHECK) $(HEADERS_FORMAT)