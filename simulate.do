onerror {quit -code 1}
onbreak {quit -code 1}
if {![file isdirectory work]} {vlib work}
file mkdir build
vlog -sv [glob rtl/*.v] [glob tb/*.sv]
vsim -onfinish stop work.tb_fifo
run -all
quit -sim
vsim -onfinish stop work.tb_system
run -all
quit -sim
vsim -onfinish stop work.tb_serial
run -all
quit -sim
quit -code 0
