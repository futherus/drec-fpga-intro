RISCV_PREFIX=riscv64-linux-gnu-

AS=$(RISCV_PREFIX)as
LD=$(RISCV_PREFIX)ld
OBJCOPY=$(RISCV_PREFIX)objcopy
OBJDUMP=$(RISCV_PREFIX)objdump

SRCS=$(wildcard *.s)
TXTS=$(SRCS:%.s=%.txt)

RISCV_SRC=fact_riscv.c
RISCV_OBJ=$(RISCV_SRC:%.c=%.o)
RISCV_TARGET=$(RISCV_SRC:%.c=%.out)
RISCV_TXT=$(RISCV_SRC:%.c=%.txt)

all: $(TXTS)

riscv-test:
	riscv64-linux-gnu-gcc -nostdlib -fomit-frame-pointer -O1 -mabi=ilp32 -march=rv32i -c $(RISCV_SRC) -o $(RISCV_OBJ)
	riscv64-linux-gnu-as -march=rv32i -mabi=ilp32 -c loader.s -o loader.o
	riscv64-linux-gnu-ld -Ttext=0x1000 -melf32lriscv loader.o $(RISCV_OBJ) -o $(RISCV_TARGET)
	make $(RISCV_TXT) # для получения файла прошивки ROM

%.txt: %.bin
	hexdump -v -e '"%08x\n"' $^ > $@

%.bin: %.out
	$(OBJCOPY) -O binary $^ $@

%.out: %.o
	$(LD) -melf32lriscv $^ -o $@ && $(OBJDUMP) -d $@

%.o: %.s
	$(AS) -march=rv32i -mabi=ilp32 -c $^ -o $@

.PHONY: all clean

.PRECIOUS: %.o %.out %.bin

clean:
	rm -f *.o *.out *.bin *.txt
