// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------

`timescale 1 ps / 1 ps

(* BLOCK_STUB = "true" *)
module vio (
  clk_0,
  probe_in0_0,
  probe_out0_0,
  probe_out1_0
);

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_0 CLK" *)
  (* X_INTERFACE_MODE = "slave CLK.CLK_0" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN vio_clk_0, INSERT_VIP 0" *)
  input clk_0;
  (* X_INTERFACE_IGNORE = "true" *)
  input [4:0]probe_in0_0;
  (* X_INTERFACE_IGNORE = "true" *)
  output [0:0]probe_out0_0;
  (* X_INTERFACE_IGNORE = "true" *)
  output [0:0]probe_out1_0;

  // stub module has no contents

endmodule
