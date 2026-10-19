//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Fri Jul 31 02:05:20 2026
//Host        : DESKTOP-GQT7BIQ running 64-bit major release  (build 9200)
//Command     : generate_target ila_wrapper.bd
//Design      : ila_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ila_wrapper
   (clk_0,
    probe0_0,
    probe1_0,
    probe2_0,
    probe3_0);
  input clk_0;
  input [17:0]probe0_0;
  input [17:0]probe1_0;
  input [4:0]probe2_0;
  input [0:0]probe3_0;

  wire clk_0;
  wire [17:0]probe0_0;
  wire [17:0]probe1_0;
  wire [4:0]probe2_0;
  wire [0:0]probe3_0;

  ila ila_i
       (.clk_0(clk_0),
        .probe0_0(probe0_0),
        .probe1_0(probe1_0),
        .probe2_0(probe2_0),
        .probe3_0(probe3_0));
endmodule
