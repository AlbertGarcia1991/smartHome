# Custom funtions
addprefixwithspace = $(addprefix $(1) , $(2))

# Directories
DEV_TOOLS_DIR = ~/dev_tools
MSPGCC_ROOT_DIR = $(DEV_TOOLS_DIR)/msp430-gcc
MSPGCC_BIN_DIR = $(MSPGCC_ROOT_DIR)/bin
MSPGCC_INCLUDE_DIR = $(MSPGCC_ROOT_DIR)/include
INCLUDE_DIRS = $(MSPGCC_INCLUDE_DIR)
LIB_DIRS = $(MSPGCC_INCLUDE_DIR)
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj
BIN_DIR = $(BUILD_DIR)/bin
TI_CSS_DIR = $(DEV_TOOLS_DIR)/ccs1271/ccs/ccs_base/DebugServer
DEBUG_BIN_DIR = $(TI_CSS_DIR)/bin
DEBUG_DRIVERS_DIR = $(TI_CSS_DIR)/drivers

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
TARGET = $(BIN_DIR)/blink
SOURCES = main.c led.c  # .c source files

OBJECT_NAMES = $(SOURCES:.c=.o)
OBJECTS = $(patsubst %, $(OBJ_DIR)/%, $(OBJECT_NAMES))

## Linking
$(TARGET): $(OBJECTS)
	@mkdir -p $(dir $@)
	@$(CC) $(LDFLAGS) $^ -o $@
	@echo "Linked $^ -> $@"

## Compiling
$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(OBJ_DIR)
	@$(CC) $(CFLAGS) -c -o $@ $^
	@echo "Built $^ -> $@"

# $^ -> Prerequisite(s)
# $@ -> Target(s)

# Phonies
.PHONY: all clean flash

## Build all
all: $(TARGET)

## Clean
clean:
	@rm -f -r $(BUILD_DIR)
	@echo "Build removed" 

## Flash (and build if not done yet)
flash: $(TARGET)
	@$(DEBUG) tilib "prog $(TARGET)"
	@echo "Flashing..."