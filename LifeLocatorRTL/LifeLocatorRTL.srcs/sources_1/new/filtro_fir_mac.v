`timescale 1ns / 1ps

module filtro_fir_mac
  #(
    parameter NB_INPUT   = 18, //! Ancho de datos de entrada (Q2.16)
    parameter NBF_INPUT  = 16,
    parameter NB_OUTPUT  = 18, //! Ancho de datos de salida
    parameter NBF_OUTPUT = 16,
    parameter NB_COEFF   = 18, //! Ancho de coeficientes
    parameter NBF_COEFF  = 16,
    parameter NTAPS      = 128 //! Número de taps
  ) 
  (
    output reg signed [NB_OUTPUT-1:0] o_os_data, 
    output reg                        o_valid,   
    input  wire signed [NB_INPUT -1:0] i_is_data, 
    input  wire                        i_en,      
    input  wire                        i_srst,    
    input  wire                        i_tick,    
    input  wire                        clk        
  );

  
  localparam NB_PROD    = NB_INPUT + NB_COEFF;             // 36 bits
  localparam NB_ACC     = NB_PROD + $clog2(NTAPS);         // 36 + 7 = 43 bits
  localparam NBF_ACC    = NBF_INPUT + NBF_COEFF;           // 32 bits fraccionarios
  localparam NBI_ACC    = NB_ACC - NBF_ACC;                // Bits enteros acumulador
  localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;
  localparam NB_SAT     = NBI_ACC - NBI_OUTPUT;

  
  reg signed [NB_COEFF-1:0] coeff [0:NTAPS-1];
  reg signed [NB_INPUT-1:0] shift_reg [0:NTAPS-1];

  initial begin
    $readmemh("coeff.mem", coeff); 
  end

  // 2. Registros de control y acumulador
  reg [$clog2(NTAPS):0] tap_ptr;
  reg signed [NB_ACC-1:0] acc;
  
  // Maquina de Estados 
  localparam ST_IDLE = 1'b0,
             ST_MAC  = 1'b1;
  reg state;

  integer k;
  always @(posedge clk) begin
    if (i_srst) begin
      state     <= ST_IDLE;
      tap_ptr   <= 0;
      acc       <= {NB_ACC{1'b0}};
      o_os_data <= {NB_OUTPUT{1'b0}};
      o_valid   <= 1'b0;
      for (k = 0; k < NTAPS; k = k + 1) begin
        shift_reg[k] <= {NB_INPUT{1'b0}};
      end
    end else if (i_en) begin
      o_valid <= 1'b0; 

      case (state)
        ST_IDLE: begin
          if (i_tick) begin
            // Shift de muestras al recibir un nuevo tick
            shift_reg[0] <= i_is_data;
            for (k = 1; k < NTAPS; k = k + 1) begin
              shift_reg[k] <= shift_reg[k-1];
            end
            
            // Inicializar acumulador con el primer tap (tap 0)
            acc     <= i_is_data * coeff[0];
            tap_ptr <= 1;
            state   <= ST_MAC;
          end
        end

        ST_MAC: begin
          // acc = acc + (x[k] * h[k])
          acc     <= acc + (shift_reg[tap_ptr] * coeff[tap_ptr]);
          tap_ptr <= tap_ptr + 1'b1;

          // Cuando procesamos los 128 taps, saturamos y finalizamos
          if (tap_ptr == NTAPS - 1) begin
            state   <= ST_IDLE;
            o_valid <= 1'b1;

            // Lógica de Saturación / Truncado de salida
            if (~|acc[NB_ACC-1 -: NB_SAT+1] || &acc[NB_ACC-1 -: NB_SAT+1]) begin
              o_os_data <= acc[NB_ACC - (NBI_ACC - NBI_OUTPUT) - 1 -: NB_OUTPUT];
            end else if (acc[NB_ACC-1]) begin
              o_os_data <= {{1'b1}, {NB_OUTPUT-1{1'b0}}}; // Saturación negativa
            end else begin
              o_os_data <= {{1'b0}, {NB_OUTPUT-1{1'b1}}}; // Saturación positiva
            end
          end
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule

