`timescale 1ns / 1ps

module det_resp #(
    parameter NB=18,
    parameter NBF = 16,
    parameter NBINS = 5,
    parameter N= 200,
    parameter FS = 20
    )(
    input clk, i_en, i_srst,
    input signed [NB-1:0] x_in,
    input i_tick,
    output reg [4:0] o_bpm, //Maximo BPM = 30
    output o_bpm_valid
    );

wire g_valid;
wire [2:0] g_bin;
wire signed [49:0] g_mod;
wire ready;

reg [2:0] max_bin = 3'b000;
reg signed [49:0] max_mod = 50'd0;

goertzel_algorithm dft(
    .clk(clk),
    .i_srst(i_srst),
    .sample_valid(i_tick),
    .x_in(x_in),
    .mag_valid(g_valid),
    .mag_bin_idx(g_bin),
    .mag2(g_mod),
    .block_done(ready)
);



//Almacenador de bins 

always @(posedge clk) begin
    if (i_srst) begin
        max_mod <= 0;
        max_bin <= 0;
        o_bpm   <= 0;
    end
    else begin
        if (g_valid) begin
            if (g_bin == 0) begin
                max_mod <= g_mod;
                max_bin <= 0;
            end
            else if (g_mod > max_mod) begin
                max_mod <= g_mod;
                max_bin <= g_bin;
            end
        end

        if (ready) begin
            case(max_bin)
                3'd0: o_bpm <= 5'd6;
                3'd1: o_bpm <= 5'd12;
                3'd2: o_bpm <= 5'd18;
                3'd3: o_bpm <= 5'd24;
                3'd4: o_bpm <= 5'd30;
                default: o_bpm <= 5'd0;
            endcase
        end
    end
end

//Estimador de BPM


assign o_bpm_valid = ready;


endmodule
