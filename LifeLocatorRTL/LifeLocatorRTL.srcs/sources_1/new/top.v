`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2026 18:04:59
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module life_locator(
    input       clk    
    );
    
    wire       i_en;
    wire       i_srst;
    wire       [4:0] o_bpm;
    wire        o_bpm_valid;
    wire       sample_clk;
    wire        o_valid_fir;
    
    wire signed [17:0] o_clutter;
    wire signed [17:0] o_fir;
    
    reg signed [17:0] signal_reg;
    wire signed [17:0] i_signal; 
    
    
    always@(posedge clk)begin
        if(i_srst == 1'b1)begin
            signal_reg <= 18'b0;
        end else begin
            if(i_en == 1'b1)begin
                signal_reg <= i_signal;
            end
        end    
    end
    
    
    filtro_clutter Clutter(
    .o_os_data (o_clutter),
    .i_is_data (signal_reg),
    .i_en      (i_en),
    .i_srst    (i_srst),
    .i_tick    (sample_clk),
    .clk       (clk)
   );
  
  //filtro_fir PasaBanda(
  //  .o_os_data (o_fir),
  //  .i_is_data (o_clutter),
  //  .i_en      (i_en),
  //  .i_srst    (i_srst),
  //  .i_tick    (sample_clk),
  //  .clk       (clk)
  //);
  
  tick_generator #(
    .CLK_FREQ(50_000_000),
    .FS(20)
    )AvanceADC(
    .i_clock(clk),
    .i_reset(i_srst),
    .o_tick(sample_clk)
    );
  
  filtro_fir_mac #(
    .NTAPS(256)
    )
    PasaBanda(
    .o_os_data (o_fir),
    .o_valid(o_valid_fir),
    .i_is_data (o_clutter),
    .i_en      (i_en),
    .i_srst    (i_srst),
    .i_tick    (sample_clk),
    .clk       (clk)
  );
    
  signal_generator Mem(
                 .i_clock(clk),
                 .i_reset(i_srst),
                 .i_tick(sample_clk),
                 .o_signal(i_signal)                 
                 );  
                 
   det_resp Bpm(
    .clk(clk),
    .i_en(i_en),
    .i_srst(i_srst),
    .x_in(o_fir),
    .i_tick(sample_clk),
    .o_bpm(o_bpm),
    .o_bpm_valid(o_bpm_valid)
   );
  
   vio u_vio
       (.clk_0(clk),
        .probe_in0_0(o_bpm),
        .probe_out0_0(i_en),
        .probe_out1_0(i_srst)
        );
        
   ila u_ila
       (.clk_0(clk),
        .probe0_0(i_signal),
        .probe1_0(o_fir),
        .probe2_0(o_bpm),
        .probe3_0(o_valid_fir)
        );
        
endmodule
