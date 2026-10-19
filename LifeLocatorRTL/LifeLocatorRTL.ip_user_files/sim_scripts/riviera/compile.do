transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr -l xpm -l xil_defaultlib \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 -l xpm -l xil_defaultlib \
"../../bd/ila/ip/ila_ila_0_0/sim/ila_ila_0_0.v" \
"../../../LifeLocatorRTL.gen/sources_1/bd/vio/ip/vio_vio_0_0/sim/vio_vio_0_0.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/Filtro_BP.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/SatTruncFP.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/filtro_clutter.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/top.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/signal_generator.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/fir_mult.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/fft_mdc_256.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/mdc_stage.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/goertzel.v" \
"../../../LifeLocatorRTL.srcs/sources_1/new/generador_tick.v" \
"../../bd/ila/sim/ila.v" \
"../../../LifeLocatorRTL.gen/sources_1/bd/vio/sim/vio.v" \

vlog -work xil_defaultlib  -incr -l xpm -l xil_defaultlib \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_clutter.sv" \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_claude.sv" \

vlog -work xil_defaultlib  -incr -v2k5 -l xpm -l xil_defaultlib \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_Filtro_BP.v" \

vlog -work xil_defaultlib  -incr -l xpm -l xil_defaultlib \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_fft.sv" \

vlog -work xil_defaultlib  -incr -v2k5 -l xpm -l xil_defaultlib \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_pruebas.v" \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_goertzel.v" \

vlog -work xil_defaultlib  -incr -l xpm -l xil_defaultlib \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_goertzel_claude.sv" \
"../../../LifeLocatorRTL.srcs/sim_1/new/tb_control_goertzel.sv" \

vlog -work xil_defaultlib \
"glbl.v"

