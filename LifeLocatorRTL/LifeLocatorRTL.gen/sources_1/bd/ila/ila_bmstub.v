// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------

`timescale 1 ps / 1 ps

(* BLOCK_STUB = "true" *)
module ila (
  clk_0,
  probe0_0,
  probe1_0,
  probe2_0,
  probe3_0
);

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_0 CLK" *)
  (* X_INTERFACE_MODE = "slave CLK.CLK_0" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN ila_clk_0, INSERT_VIP 0" *)
  input clk_0;
  (* X_INTERFACE_IGNORE = "true" *)
  input [17:0]probe0_0;
  (* X_INTERFACE_IGNORE = "true" *)
  input [17:0]probe1_0;
  (* X_INTERFACE_IGNORE = "true" *)
  input [4:0]probe2_0;
  (* X_INTERFACE_IGNORE = "true" *)
  input [0:0]probe3_0;

  // stub module has no contents

endmodule
