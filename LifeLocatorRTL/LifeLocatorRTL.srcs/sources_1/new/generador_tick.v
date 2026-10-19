`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.07.2026 20:24:43
// Design Name: 
// Module Name: generador_tick
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

module tick_generator #(
    parameter CLK_FREQ = 50_000_000,
    parameter FS       = 20
)(
    input   i_clock,
    input   i_reset,
    output reg  o_tick
);
    localparam LIMIT = (CLK_FREQ / FS) - 1;
    reg [31:0] count;

    always @(posedge i_clock or posedge i_reset) begin
        if (i_reset) begin
            count  <= 0;
            o_tick <= 1'b0;
        end else begin
            if (count == LIMIT) begin
                count  <= 0;
                o_tick <= 1'b1; // Pulso de 1 ciclo de reloj
            end else begin
                count  <= count + 1'b1;
                o_tick <= 1'b0;
            end
        end
    end
endmodule
