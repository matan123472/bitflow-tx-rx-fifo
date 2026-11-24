IVERILOG ?= iverilog
VVP ?= vvp
RTL := $(wildcard rtl/*.v)
.PHONY: test clean fifo system serial
test: fifo system serial
fifo system serial: %: build/tb_%.vvp
	$(VVP) $<
build/tb_%.vvp: tb/tb_%.sv $(RTL)
	@mkdir -p build
	$(IVERILOG) -g2012 -Wall -s tb_$* -o $@ $(RTL) $<
clean:
	rm -rf build
