TOP = tb_cpu
OUT = sim.out

SRCS = \
	tb_cpu.sv \
	cpu_top.sv \
	regfile.sv \
	alu.sv \
	imem.sv \
	dmem.sv \
	if_id_reg.sv \
	ex_wb_reg.sv \
	decoder.sv \
	hazard_unit.sv

all: run

compile:
	iverilog -g2012 -o sim.out tb_cpu.sv cpu_top.sv regfile.sv alu.sv imem.sv dmem.sv if_id_reg.sv ex_wb_reg.sv decoder.sv hazard_unit.sv

run: compile
	vvp $(OUT)

wave: compile
	vvp $(OUT)
	gtkwave dump.vcd

clean:
	rm -f $(OUT) dump.vcd