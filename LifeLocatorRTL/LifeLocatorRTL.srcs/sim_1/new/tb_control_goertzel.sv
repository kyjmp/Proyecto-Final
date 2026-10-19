`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.07.2026 17:20:29
// Design Name: 
// Module Name: tb_control_goertzel
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

module tb_det_resp;

localparam NB = 18;

logic clk;
logic rst_n;
logic i_en;


logic signed [NB-1:0] x_in;

wire [4:0] o_bpm;
wire o_bpm_valid;
wire valid;
////////////////////////////////////////////////////////////

det_resp #(
    .SAMPLE_DIV(5_000_000)
    )
    DUT(
    .clk(clk),
    .rst_n(rst_n),
    .i_en(i_en),
    .x_in(x_in),
    .o_bpm(o_bpm),
    .o_bpm_valid(o_bpm_valid),
    .valid(valid)
);

////////////////////////////////////////////////////////////

initial
    clk = 0;

always #5 clk = ~clk;      //100 MHz

////////////////////////////////////////////////////////////

real fs = 20.0;
real f;
real t;

integer n;

integer sample = 0;


always @(posedge valid) begin
    x_in <= $rtoi(32767*$sin(2.0*3.1415926535*f*sample/fs));
    sample++;
end

initial begin
    rst_n = 0; 
    i_en = 1; 
    x_in = 0; 
    repeat(10) @(posedge clk); 
    rst_n = 1;
    
    #10ms f = 0.1;
    $display("f= %f", f);
    #100ms f = 0.5;
    $display("f= %f", f);
end



endmodule