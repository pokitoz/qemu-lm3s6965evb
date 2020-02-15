BINARY := cm3.elf
MACHINE := lm3s6965evb

CMSIS ?= ./cmsis
QEMU_PATH ?= ./qemu/arm-softmmu/qemu-system-arm
TOOLCHAIN ?= ./gcc/bin

QEMU_COMMAND := $(QEMU_PATH) \
	-machine $(MACHINE) \
	-cpu cortex-m3 \
	-m 4096 \
	-nographic \
	-semihosting \
	-device loader,file=$(BINARY) \
	-machine accel=tcg

BINARY_OBJDUMP := objdump_$(BINARY)

CROSS_COMPILE = $(TOOLCHAIN)/arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
GDB = $(CROSS_COMPILE)gdb
OBJ = $(CROSS_COMPILE)objdump

LINKER_SCRIPT = gcc_arm.ld

SRC_ASM = $(CMSIS)/Device/ARM/ARMCM3/Source/GCC/startup_ARMCM3.S

SRC_C = $(CMSIS)/Device/ARM/ARMCM3/Source/system_ARMCM3.c \
	start.c \
	main.c

INCLUDE_FLAGS = -I$(CMSIS)/Device/ARM/ARMCM3/Include \
	-I$(CMSIS)/CMSIS/Core/Include \
	-I.

CFLAGS = -mcpu=cortex-m3 \
	-g3 \
	-specs=nano.specs -specs=nosys.specs \
        -specs=rdimon.specs \
	-Wall \
	$(INCLUDE_FLAGS) \
	-mthumb \
	-nostartfiles

all: $(BINARY)

boot.o: $(SRC_ASM)
	$(CC) $(CFLAGS) -c $^ -o $@

$(BINARY): $(SRC_C) boot.o
	$(CC) $^ $(CFLAGS) -T $(LINKER_SCRIPT) -o $@
	$(OBJ) -D $@ > $(BINARY_OBJDUMP)


# Ctrl-A, then X to quit
run: $(BINARY)
	-$(QEMU_COMMAND) -d int,cpu_reset
	echo $? " has exited"

gdbserver: $(BINARY)
	$(QEMU_COMMAND) -S -s -d int,cpu_reset

help:
	$(QEMU_PATH) --machine help

gdb: $(BINARY)
	$(GDB) $(BINARY) -ex "target remote:1234"

clean:
	rm -f $(BINARY_OBJDUMP) *.o *.elf 
