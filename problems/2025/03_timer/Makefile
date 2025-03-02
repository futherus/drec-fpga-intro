TB_LIST := dec_counter_tb.v

RTL_LIST := dec_counter.v

sim: $(TB_LIST) $(RTL_LIST)
	iverilog $^ -o sim
	./sim

gui:
	quartus fpga &

syn:
	quartus_sh --flow compile fpga

fpga:
	quartus_pgm -c "USB-Blaster" -m JTAG -o "p;output/fpga.sof"

drc:
	quartus_drc fpga

clean:
	rm -rf sim dump.vcd
	rm -rf db incremental_db output fpga.qws greybox_tmp *.bak

.PHONY: syn fpga clean gui drc
