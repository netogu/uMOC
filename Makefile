######################################
# Target
######################################
TARGET = stm32g4-minimal
DEVICE = STM32G474xx

######################################
# Building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -Og

#######################################
# Debug 
#######################################
DEBUGER_PATH = openocd
DEBUGER_CONF = src/board/openocd.cfg

#######################################
# paths
#######################################
# Build path
BUILD_DIR = build
#
# Tinyusb Library
TINYUSB = external/tinyusb/src

######################################
# Sources
######################################
# C sources
C_SOURCES = $(wildcard src/*.c) 
C_SOURCES += $(wildcard src/external/*.c)
C_SOURCES += $(wildcard src/hardware/*.c) 
C_SOURCES += $(wildcard src/hardware/*/*.c) 
# C_SOURCES += $(wildcard src/lib/*.c)
# C_SOURCES += $(wildcard src/lib/*/*.c)
C_SOURCES += $(wildcard src/board/config.c) 
# C_SOURCES += $(wildcard $(TINYUSB)/*.c) 
# C_SOURCES += $(wildcard $(TINYUSB)/device/*.c) 
# C_SOURCES += $(wildcard $(TINYUSB)/common/*.c) 
# C_SOURCES += $(wildcard $(TINYUSB)/class/cdc/*.c) 
# C_SOURCES += $(wildcard $(TINYUSB)/portable/st/stm32_fsdev/*.c) 
# C_SOURCES += $(wildcard $(TINYUSB)/portable/st/synopsys/*.c) 
# C_SOURCES += $(wildcard $(TINYUSB)/portable/st/typec/*.c) 
# ASM sources
ASM_SOURCES =  \
src/hardware/stm32g4/startup.s


######################################
# Includes
######################################
# AS includes
AS_INCLUDES = 

# C includes
C_INCLUDES =  \
-Isrc/external/CMSIS/Device/ST/STM32G4xx/Include \
-Isrc/external/CMSIS/Include \
-Isrc/external/tinyusb/src \
-Isrc \

#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT = src/hardware/stm32g4/linker_script.ld

#######################################
# binaries
#######################################
PREFIX = arm-none-eabi-
# The gcc compiler bin path can be either defined in make command via GCC_PATH variable (> make GCC_PATH=xxx)
# either it can be added to the PATH environment variable.
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)gcc
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

 
#######################################
# CFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m4

# fpu
FPU = -mfpu=fpv4-sp-d16

# float-abi
FLOAT-ABI = -mfloat-abi=hard

# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI) -D$(DEVICE)

# macros for gcc
# AS defines
AS_DEFS = 

# # C defines
C_DEFS =  \
-DSTM32G474xx


# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS += $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"
CFLAGS += -nostdlib
CFLAGS += -fno-use-cxa-atexit


LIBS = -lc -lm -lnosys 
LIBDIR = 
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections


# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin


#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR):
	mkdir $@		

#######################################
# clean up
#######################################
clean:
	-rm -fR $(BUILD_DIR)
  
#######################################
# Flash (openocd)
#######################################
flash:
	$(DEBUGER_PATH) -f $(DEBUGER_CONF) -c "program $(BUILD_DIR)/$(TARGET).elf verify reset exit"

#######################################
# Debug (openocd)
#######################################
debug:
	$(DEBUGER_PATH) -f $(DEBUGER_CONF) & gdb-multiarch -ex 'target extended-remote localhost:3333' $(BUILD_DIR)/$(TARGET).elf
#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)

# *** EOF ***
