`timescale 1ns / 1ps

module goertzel_algorithm #(
    parameter integer DATA_WIDTH = 18,   
    parameter integer COEF_WIDTH = 18,   
    parameter integer FRAC_BITS  = 16,   
    parameter integer ACC_WIDTH  = 32,   // ancho de los acumuladores v1/v2 
    parameter integer NBINS      = 5,    // 0.1,0.2,0.3,0.4,0.5 Hz
    parameter integer N          = 200,  // muestras por bloque (Fs/N = 0.1 Hz)
    parameter integer MAG_WIDTH  = 2*ACC_WIDTH + 2 - FRAC_BITS,
    parameter integer BAND_WIDTH = MAG_WIDTH + 4  // margen extra al sumar 5 bins
) (
    input  wire                          clk,
    input  wire                          i_srst,
    input  wire                          sample_valid,
    input  wire signed [DATA_WIDTH-1:0]  x_in,          
    output reg                           mag_valid,
    output reg  [2:0]                    mag_bin_idx,   
    output reg  signed [MAG_WIDTH-1:0]   mag2,          
    output reg                           block_done // pulso: bloque de N muestras cerrado
);


    // Coeficientes 2*cos(2*pi*k/N) para N=200, k=1..5, en Q2.16 signed
    // (18 bits: 1 signo + 1 entero + 16 fraccionarios, rango ~ -2..+2)

    function signed [COEF_WIDTH-1:0] get_coeff(input [2:0] idx);
        case (idx)
            3'd0: get_coeff = 18'sd131010; // k=1 -> 0.1 Hz  (2*cos(2*pi*1/200)=1.999013)
            3'd1: get_coeff = 18'sd130813; // k=2 -> 0.2 Hz  (1.996053)
            3'd2: get_coeff = 18'sd130485; // k=3 -> 0.3 Hz  (1.991051)
            3'd3: get_coeff = 18'sd130037; // k=4 -> 0.4 Hz  (1.984210)
            3'd4: get_coeff = 18'sd129458; // k=5 -> 0.5 Hz  (1.975377)
            default: get_coeff = 18'sd0;
        endcase
    endfunction

    
    // Estado por bin
    
    reg signed [ACC_WIDTH-1:0] v1_mem [0:NBINS-1];
    reg signed [ACC_WIDTH-1:0] v2_mem [0:NBINS-1];

    localparam integer BIN_W = 3;               // clog2(NBINS) redondeado, alcanza para 5
    localparam integer NCNT_W = 8;              // clog2(N), alcanza hasta 255 (N=200)

    reg [BIN_W-1:0]  bin_idx;
    reg [NCNT_W-1:0] n_cnt;
    reg signed [DATA_WIDTH-1:0] x_reg;

    // Únicos operandos/resultados de multiplicación: se reutilizan para
    // TODO (recurrencia y magnitud) -> un solo multiplicador físico.
    reg signed [COEF_WIDTH-1:0]            coef_r;
    reg signed [COEF_WIDTH+ACC_WIDTH-1:0]  mult_r;      // coeff * s
    reg signed [2*ACC_WIDTH-1:0]           v1_r, v2_r, cross_r; // s1^2, s2^2, s1*s2

    // -------------------------------------------------------------------
    // FSM
    // -------------------------------------------------------------------
    localparam [2:0]
        ST_IDLE     = 3'd0,
        ST_UPD_MUL  = 3'd1,
        ST_UPD_ADD  = 3'd2,
        ST_MAG_MUL1 = 3'd3,  // p1 = v1*v1
        ST_MAG_MUL2 = 3'd4,  // p2 = v2*v2
        ST_MAG_MUL3 = 3'd5,  // cross = v1*v2
        ST_MAG_MUL4 = 3'd6,  // p3 = coeff*cross ; emitir mag2
        ST_DONE     = 3'd7;
        
    reg [2:0] state;

    integer i;

    always @(posedge clk or posedge i_srst) begin
        if (i_srst) begin
            state              <= ST_IDLE;
            bin_idx            <= 0;
            n_cnt              <= 0;
            mag_valid          <= 1'b0;
            mag_bin_idx        <= 0;
            mag2               <= 0;
            block_done         <= 1'b0;
            //band_energy_valid  <= 1'b0;
            //band_energy        <= 0;
            for (i = 0; i < NBINS; i = i + 1) begin
                v1_mem[i] <= 0;
                v2_mem[i] <= 0;
            end
        end else begin
            // valores por defecto (pulsos de 1 ciclo)
            mag_valid         <= 1'b0;
            block_done        <= 1'b0;
            //band_energy_valid <= 1'b0;

            case (state)


                // Esperar la próxima muestra (llega a Fs = 20 Hz)

                ST_IDLE: begin
                    if (sample_valid) begin
                        x_reg   <= x_in;
                        bin_idx <= 0;
                        state   <= ST_UPD_MUL;
                    end
                end

                // ---- Actualización de la recurrencia, 2 ciclos/bin -----
                ST_UPD_MUL: begin
                    coef_r <= get_coeff(bin_idx);
                    mult_r <= get_coeff(bin_idx) * v1_mem[bin_idx];
                    state  <= ST_UPD_ADD;
                end

                ST_UPD_ADD: begin : upd_add_blk
                    reg signed [ACC_WIDTH-1:0] scaled;
                    reg signed [ACC_WIDTH-1:0] v0;
                    scaled = mult_r >>> FRAC_BITS;              // des-escala Q2.16
                    v0     = x_reg + scaled - v2_mem[bin_idx];   // s[n] = x+coeff*s1-s2
                    v2_mem[bin_idx] <= v1_mem[bin_idx];
                    v1_mem[bin_idx] <= v0;

                    if (bin_idx == NBINS-1) begin
                        if (n_cnt == N-1) begin
                            // bloque completo -> pasar a calcular magnitudes
                            n_cnt   <= 0;
                            bin_idx <= 0;
                            //band_energy <= 0;
                            state   <= ST_MAG_MUL1;
                        end else begin
                            n_cnt <= n_cnt + 1'b1;
                            state <= ST_IDLE;
                        end
                    end else begin
                        bin_idx <= bin_idx + 1'b1;
                        state   <= ST_UPD_MUL;
                    end
                end

                // ---- Cálculo de |X[k]|^2 = s1^2+s2^2-coeff*s1*s2 -------
                // 4 ciclos por bin, reutilizando el mismo multiplicador
                ST_MAG_MUL1: begin
                    v1_r  <= v1_mem[bin_idx] * v1_mem[bin_idx];
                    state <= ST_MAG_MUL2;
                end

                ST_MAG_MUL2: begin
                    v2_r  <= v2_mem[bin_idx] * v2_mem[bin_idx];
                    state <= ST_MAG_MUL3;
                end

                ST_MAG_MUL3: begin
                    cross_r <= v1_mem[bin_idx] * v2_mem[bin_idx];
                    state   <= ST_MAG_MUL4;
                end

                ST_MAG_MUL4: begin : mag_out_blk
                    reg signed [COEF_WIDTH+2*ACC_WIDTH-1:0] v3_full;
                    reg signed [2*ACC_WIDTH-1:0]            v3_scaled;
                    reg signed [2*ACC_WIDTH+1:0]             mag2_full;   // 32 bits fraccionarios
                    reg signed [MAG_WIDTH-1:0]                mag2_v;      // reescalado a 16 frac

                    v3_full   = get_coeff(bin_idx) * cross_r;
                    v3_scaled = v3_full >>> FRAC_BITS;
                    mag2_full = v1_r + v2_r - v3_scaled;         // Q_.32 (32 bits fraccionarios)
                    mag2_v    = mag2_full >>> FRAC_BITS;         // -> Q_.16 (mismo formato que x_in)

                    mag_valid    <= 1'b1;
                    mag_bin_idx  <= bin_idx;
                    mag2         <= mag2_v;
                    //band_energy  <= band_energy + mag2_v;

                    // limpiar el estado del bin para el próximo bloque
                    v1_mem[bin_idx] <= 0;
                    v2_mem[bin_idx] <= 0;

                    if (bin_idx == NBINS-1) begin
                        //band_energy_valid <= 1'b1;
                        state             <= ST_DONE;
                    end else begin
                        bin_idx <= bin_idx + 1'b1;
                        state   <= ST_MAG_MUL1;
                    end
                end

                ST_DONE: begin
                    block_done        <= 1'b1;
                    state             <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule

