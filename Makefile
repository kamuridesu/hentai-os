ODIN = odin
AS = as
LD = ld
QEMU = qemu-system-i386

ODIN_FLAGS = -target:linux_i386 -build-mode:obj -no-crt -default-to-nil-allocator -no-thread-local $(EXTRA_FLAGS)
LD_FLAGS = -m elf_i386 -nostdlib -static
AS_FLAGS = --32
QEMU_FLAGS = -device isa-debug-exit,iobase=0xf4,iosize=0x04 -serial stdio -display none

LINKER_SCRIPT = linker.ld
KERNEL_ELF = kernel.elf
ASM_FOLDER = asm
OBJ_FOLDER = obj
OBJECTS = *.o

AS_SRCS = $(wildcard $(ASM_FOLDER)/*.s)
AS_OBJS = $(patsubst $(ASM_FOLDER)/%.s, $(OBJ_FOLDER)/%.o, $(AS_SRCS))

.PHONY: all build link run clean test

all: build link

build: $(OBJ_FOLDER) $(AS_OBJS)
	$(ODIN) build src/ $(ODIN_FLAGS) -out:$(OBJ_FOLDER)/

$(OBJ_FOLDER)/%.o: $(ASM_FOLDER)/%.s
	$(AS) $(AS_FLAGS) $< -o $@

$(OBJ_FOLDER):
	mkdir -p $(OBJ_FOLDER)

link: build
	$(LD) -T $(LINKER_SCRIPT) $(LD_FLAGS) -o $(KERNEL_ELF) $(OBJ_FOLDER)/$(OBJECTS)

run: all
	$(QEMU) -kernel $(KERNEL_ELF)

clean:
	rm -f $(OBJ_FOLDER)/$(OBJECTS) $(KERNEL_ELF)

include test.Makefile

