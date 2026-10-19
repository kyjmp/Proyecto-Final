`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2026 01:41:14
// Design Name: 
// Module Name: filtro_clutter
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

module filtro_clutter
#(
    parameter NB_INPUT   = 18,
    parameter NBF_INPUT  = 16,

    parameter NB_OUTPUT  = 18,
    parameter NBF_OUTPUT = 16,

    parameter NB_ALPHA   = 18,
    parameter NBF_ALPHA  = 16
)
(
    input                               clk,
    input                               i_srst,
    input                               i_en,
    input                               i_tick,

    input  signed [NB_INPUT-1:0]         i_is_data,

    output signed [NB_OUTPUT-1:0]        o_os_data
);


// Parámetros


localparam signed [NB_ALPHA-1:0] ONE_Q = (1<<NBF_ALPHA); //Uno

localparam signed [NB_ALPHA-1:0] ALPHA = 18'h0F900;

localparam signed [NB_ALPHA-1:0] BETA = ONE_Q - ALPHA;  // 1 - alfa

localparam NB_MULT = NB_INPUT + NB_ALPHA;



reg signed [NB_OUTPUT-1:0] clutter_reg;


reg signed [NB_MULT-1:0] mult_alpha;
reg signed [NB_MULT-1:0] mult_beta;
reg signed [NB_MULT:0] clutter_next;

reg signed [NB_OUTPUT-1:0] output_reg;


// Multiplicadores

always @(posedge clk)
begin
    if(i_srst)
    begin
        mult_alpha <= 0;
        mult_beta  <= 0;
    end
    else if(i_en && i_tick)
    begin
        mult_alpha <= clutter_reg * ALPHA;
        mult_beta  <= i_is_data * BETA;
    end
end


// Suma

always @(posedge clk)

begin
    if(i_srst)
        clutter_next <= 0;
    else if(i_en && i_tick)
        clutter_next <= mult_alpha + mult_beta;
end


// Truncado

wire signed [NB_OUTPUT-1:0] clutter_sat;

SatTruncFP
#(
    .NB_XI(NB_MULT+1),
    .NBF_XI(NBF_INPUT+NBF_ALPHA),
    .NB_XO(NB_OUTPUT),
    .NBF_XO(NBF_OUTPUT)
)
TRUNC_CLUTTER
(
    .i_data(clutter_next),
    .o_data(clutter_sat)
);


// Registro del clutter


always @(posedge clk)
begin
    if(i_srst)
        clutter_reg <= 0;
    else if(i_en && i_tick)
        clutter_reg <= clutter_sat;
end


// Salida


always @(posedge clk)
begin
    if(i_srst)
        output_reg <= 0;
    else if(i_en && i_tick)
        output_reg <= i_is_data - clutter_reg;
end

assign o_os_data = output_reg;

endmodule