//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Fri Jul 31 02:33:41 2026
//Host        : DESKTOP-GQT7BIQ running 64-bit major release  (build 9200)
//Command     : generate_target vio_wrapper.bd
//Design      : vio_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module vio_wrapper
   (clk_0,
    probe_in0_0,
    probe_out0_0,
    probe_out1_0);
  input clk_0;
  input [4:0]probe_in0_0;
  output [0:0]probe_out0_0;
  output [0:0]probe_out1_0;

  wire clk_0;
  wire [4:0]probe_in0_0;
  wire [0:0]probe_out0_0;
  wire [0:0]probe_out1_0;

  vio vio_i
       (.clk_0(clk_0),
        .probe_in0_0(probe_in0_0),
        .probe_out0_0(probe_out0_0),
        .probe_out1_0(probe_out1_0));
endmodule
