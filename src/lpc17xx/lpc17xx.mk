GCC_ARM_ON_PATH = $(shell command -v arm-none-eabi-gcc >/dev/null; echo $$?)

ifneq ($(GCC_ARM_ON_PATH),0)
GCC_BIN = ../dependencies/gcc-arm-embedded/bin/
endif

ifndef JTAG_INTERFACE
	JTAG_INTERFACE = olimex-arm-usb-ocd
endif

OBJDIR = build/lpc17xx
OPENOCD_CONF_BASE = ../conf/openocd
TARGET = $(BASE_TARGET)-lpc17xx
LIBS_PATH = libs
CMSIS_PATH = ./$(LIBS_PATH)/CDL/CMSISv2p00_LPC17xx
DRIVER_PATH = ./$(LIBS_PATH)/CDL/LPC17xxLib
INCLUDE_PATHS = -I. -I./$(LIBS_PATH)/cJSON -I./$(LIBS_PATH)/emqueue \
				-I./$(LIBS_PATH)/nxpUSBlib/Drivers \
				-I$(DRIVER_PATH)/inc -I./$(LIBS_PATH)/BSP -I$(CMSIS_PATH)/inc
ifeq ($(BOOTLOADER), 1)
LINKER_SCRIPT = lpc17xx/LPC17xx-bootloader.ld
else
LINKER_SCRIPT = lpc17xx/LPC17xx-baremetal.ld
endif

CC = $(GCC_BIN)arm-none-eabi-gcc
CPP = $(GCC_BIN)arm-none-eabi-g++
AS_FLAGS = -c -mcpu=cortex-m3 -mthumb --defsym RAM_MODE=0
CC_FLAGS = -c -fno-common -fmessage-length=0 -Wall -fno-exceptions \
		   -mcpu=cortex-m3 -mthumb -ffunction-sections -fdata-sections \
		   -Wno-char-subscripts -Wno-unused-but-set-variable -Werror
ONLY_C_FLAGS = -std=gnu99
ONLY_CPP_FLAGS = -std=gnu++0x
CC_SYMBOLS += -DTOOLCHAIN_GCC_ARM -DUSB_DEVICE_ONLY -D__LPC17XX__ -DBOARD=9

ifeq ($(PLATFORM), BLUEBOARD)
CC_SYMBOLS += -DBLUEBOARD
else
CC_SYMBOLS += -DFORDBOARD
endif

AS = $(GCC_BIN)arm-none-eabi-as
LD = $(GCC_BIN)arm-none-eabi-g++
LD_FLAGS = -mcpu=cortex-m3 -mthumb -Wl,--gc-sections,-Map=$(OBJDIR)/$(BASE_TARGET).map
LD_SYS_LIBS = -lstdc++ -lsupc++ -lm -lc -lgcc

OBJCOPY = $(GCC_BIN)arm-none-eabi-objcopy

LOCAL_C_SRCS = $(wildcard *.c)
LOCAL_C_SRCS += $(wildcard lpc17xx/*.c)
LIB_C_SRCS += $(wildcard $(LIBS_PATH)/nxpUSBlib/Drivers/USB/Core/*.c)
LIB_C_SRCS += $(wildcard $(LIBS_PATH)/nxpUSBlib/Drivers/USB/Core/LPC/*.c)
LIB_C_SRCS += $(wildcard $(LIBS_PATH)/nxpUSBlib/Drivers/USB/Core/LPC/HAL/LPC17XX/*.c)
LIB_C_SRCS += $(wildcard $(LIBS_PATH)/nxpUSBlib/Drivers/USB/Core/LPC/DCD/LPC17XX/*.c)
LIB_C_SRCS += $(wildcard $(LIBS_PATH)/nxpUSBlib/Drivers/USB/Core/LPC/DCD/LPC17XX/*.c)
LIB_C_SRCS += $(wildcard $(LIBS_PATH)/BSP/*.c)
LIB_C_SRCS += $(wildcard $(LIBS_PATH)/BSP/LPCXpressoBase_RevB/*.c)
LIB_C_SRCS += $(CMSIS_PATH)/src/core_cm3.c
LIB_C_SRCS += $(CMSIS_PATH)/src/system_LPC17xx.c
LIB_C_SRCS += $(wildcard $(DRIVER_PATH)/src/*.c)
LIB_C_SRCS += $(LIBS_PATH)/cJSON/cJSON.o
LIB_C_SRCS += $(LIBS_PATH)/emqueue/emqueue.o
LOCAL_CPP_SRCS = $(wildcard *.cpp) $(wildcard lpc17xx/*.cpp)
LOCAL_OBJ_FILES = $(LOCAL_C_SRCS:.c=.o) $(LOCAL_CPP_SRCS:.cpp=.o) $(LIB_C_SRCS:.c=.o)
OBJECTS = $(patsubst %,$(OBJDIR)/%,$(LOCAL_OBJ_FILES))

TARGET_BIN = $(OBJDIR)/$(TARGET).bin
TARGET_ELF = $(OBJDIR)/$(TARGET).elf

ifdef DEBUG
CC_FLAGS += -g -ggdb
else
CC_FLAGS += -Os -Wno-uninitialized
endif

BSP_EXISTS = $(shell test -e $(LIBS_PATH)/BSP/bsp.h; echo $$?)
CDL_EXISTS = $(shell test -e $(LIBS_PATH)/CDL/README.mkd; echo $$?)
USBLIB_EXISTS = $(shell test -e $(LIBS_PATH)/nxpUSBlib/README.mkd; echo $$?)
ifneq ($(BSP_EXISTS),0)
$(error BSP dependency is missing - did you run "git submodule init && git submodule update"?)
endif

ifneq ($(CDL_EXISTS),0)
$(error CDL dependency is missing - did you run "git submodule init && git submodule update"?)
endif

ifneq ($(USBLIB_EXISTS),0)
$(error nxpUSBlib dependency is missing - did you run "git submodule init && git submodule update"?)
endif

all: $(TARGET_BIN)

flash: all
	@echo "Flashing $(PLATFORM) via JTAG with OpenOCD..."
	openocd -s $(OPENOCD_CONF_BASE) -f $(BASE_TARGET).cfg -f interface/$(JTAG_INTERFACE)-custom.cfg -f flash.cfg
	@echo "$(GREEN)Flashed $(PLATFORM) successfully.$(COLOR_RESET)"

gdb: all
	@openocd -f $(OPENOCD_CONF_BASE)/gdb.cfg

.s.o:
	$(AS) $(AS_FLAGS) -o $@ $<

$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CC_FLAGS) $(CC_SYMBOLS) $(ONLY_C_FLAGS) $(INCLUDE_PATHS) -o $@ $<

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CPP) $(CC_FLAGS) $(CC_SYMBOLS) $(ONLY_CPP_FLAGS) $(INCLUDE_PATHS) -o $@ $<

$(TARGET_ELF): $(OBJECTS)
	$(LD) $(LD_FLAGS) -T$(LINKER_SCRIPT) -Llpc17xx -o $@ $^ $(LD_SYS_LIBS)

$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) -O binary $< $@

ispflash: all
	@lpc21isp -bin $(TARGET_BIN) $(SERIAL_PORT) 115200 1474
