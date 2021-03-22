PROGRAM ?= hello

FILEPATH = softwares/$(PROGRAM)
# paths
BSP = bsp
CORE = $(BSP)/core
DRIVERS = $(BSP)/drivers
INCLUDE = $(BSP)/include

RISCV=riscv32-unknown-elf-
GCC=$(RISCV)gcc
OBJDMP=$(RISCV)objdump
GCCFLAGS=-march=rv32i -mabi=ilp32 -mcmodel=medany
OBJFLAGS=--disassemble-all --disassemble-zeroes 
# --section=.text --section=.text.startup --section=.text.init --section=.data
LINK_FLAGS = -march=rv32i -mabi=ilp32 -static -nostdlib -nostartfiles -T $(CORE)/link.ld



.PHONY: build build-drivers compile-drivers build-include build-core upload

upload : build
	@echo "Uploading..."

compile-drivers :
	@mkdir -p generated
	$(GCC) $(GCCFLAGS) -I$(INCLUDE) -c $(CORE)/init.c -o generated/init.o -lgcc
	$(GCC) $(GCCFLAGS) -I$(INCLUDE) -c $(CORE)/trap.c -o generated/trap.o -lgcc
	$(GCC) $(GCCFLAGS) -I$(INCLUDE) -c $(DRIVERS)/gpio/gpio.c -o generated/gpio.o -lgcc
	$(GCC) $(GCCFLAGS) -I$(INCLUDE) -c $(DRIVERS)/plic/plic.c -o generated/plic.o -lgcc
	

build-drivers : compile-drivers
	$(RISCV)ar rcs generated/drivers.a generated/gpio.o generated/plic.o

build : clean build-drivers
	@echo "building $(FILEPATH)/$(PROGRAM).c"
	@mkdir $(FILEPATH)/output
	$(GCC) $(GCCFLAGS) -I$(INCLUDE) -I$(DRIVERS)/gpio -c $(FILEPATH)/$(PROGRAM).c -o $(FILEPATH)/output/$(PROGRAM).o -lgcc
	$(GCC) $(LINK_FLAGS) $(CORE)/start.S $(CORE)/trap.S generated/gpio.o generated/plic.o generated/trap.o $(FILEPATH)/output/$(PROGRAM).o -o $(FILEPATH)/output/$(PROGRAM).merl -lgcc
	$(OBJDMP) $(OBJFLAGS) $(FILEPATH)/output/$(PROGRAM).merl > $(FILEPATH)/output/$(PROGRAM).dump 
	$(RISCV)elf2hex --bit-width 32 --input $(FILEPATH)/output/$(PROGRAM).merl --output program.hex

	

.PHONY: clean
clean:
	rm -rf $(FILEPATH)/output
	rm -rf generated
	rm -f program.hex
	