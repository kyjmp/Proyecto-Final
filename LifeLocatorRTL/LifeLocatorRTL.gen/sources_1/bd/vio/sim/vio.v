//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Fri Jul 31 02:33:41 2026
//Host        : DESKTOP-GQT7BIQ running 64-bit major release  (build 9200)
//Command     : generate_target vio.bd
//Design      : vio
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "vio,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=vio,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=1,numReposBlks=1,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "vio.hwdef" *) 
module vio
   (clk_0,
    probe_in0_0,
    probe_out0_0,
    probe_out1_0);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_0, CLK_DOMAIN vio_clk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input clk_0;
  input [4:0]probe_in0_0;
  output [0:0]probe_out0_0;
  output [0:0]probe_out1_0;

  wire clk_0_1;
  wire [4:0]probe_in0_0_1;
  wire [0:0]vio_0_probe_out0;
  wire [0:0]vio_0_probe_out1;

  assign clk_0_1 = clk_0;
  assign probe_in0_0_1 = probe_in0_0[4:0];
  assign probe_out0_0[0] = vio_0_probe_out0;
  assign probe_out1_0[0] = vio_0_probe_out1;
  vio_vio_0_0 vio_0
       (.clk(clk_0_1),
        .probe_in0(probe_in0_0_1),
        .probe_out0(vio_0_probe_out0),
        .probe_out1(vio_0_probe_out1));
endmodule
