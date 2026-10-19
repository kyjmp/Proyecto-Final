`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.07.2026 00:57:55
// Design Name: 
// Module Name: tb_claude
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

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_filtro_fir
// DUT       : filtro_fir  (FIR pasa banda, 256 taps)
// Diseno    : Fs = 20 Hz , banda pasante 0.05 Hz - 0.5 Hz
//
// Requiere que "coeff.mem" (generado con gen_coeff.py) este en el
// directorio de simulacion de Vivado (o agregar su ruta al $readmemh
// del DUT / al "Simulation Sources" set).
//
// Genera "fir_tb_output.csv" con columnas: sample,t_s,x_in,y_out
// para graficar en MATLAB/Python/Octave y verificar la respuesta.
//////////////////////////////////////////////////////////////////////////////////

module tb_filtro_fir_1;

  // ---------------- Parametros (deben coincidir con el DUT) ----------------
  localparam NB_INPUT   = 18;
  localparam NBF_INPUT  = 16;
  localparam NB_OUTPUT  = 18;
  localparam NBF_OUTPUT = 16;
  localparam NB_COEFF   = 18;
  localparam NBF_COEFF  = 16;

  // Periodo de reloj de simulacion (arbitrario, solo mueve la logica digital)
  localparam real CLK_PERIOD = 10.0; // ns

  // Frecuencia de muestreo REAL que representa el diseno del filtro
  localparam real FS = 20.0; // Hz

  // ---------------- Senales ----------------
  reg                          clk;
  reg                          i_srst;
  reg                          i_en;
  reg i_tick;
  reg  signed [NB_INPUT -1:0]  i_is_data;
  wire signed [NB_OUTPUT-1:0]  o_os_data;
  wire o_valid;

  integer sample_idx;
  integer fout;
  integer i;
  real    t2, val2;

  // ---------------- DUT ----------------
  filtro_fir_mac #(
    .NB_INPUT   (NB_INPUT),
    .NBF_INPUT  (NBF_INPUT),
    .NB_OUTPUT  (NB_OUTPUT),
    .NBF_OUTPUT (NBF_OUTPUT),
    .NB_COEFF   (NB_COEFF),
    .NBF_COEFF  (NBF_COEFF),
    .NTAPS(256)
  ) dut (
    .o_os_data (o_os_data),
    .o_valid(o_valid),
    .i_is_data (i_is_data),
    .i_en      (i_en),
    .i_tick (i_tick),
    .i_srst    (i_srst),
    .clk       (clk)
  );

  // ---------------- Reloj ----------------
  initial clk = 1'b0;
  always #(CLK_PERIOD/2.0) clk = ~clk;

  // ---------------- Conversion real -> punto fijo Q(NB_INPUT-NBF_INPUT).NBF_INPUT ----------------
  function automatic signed [NB_INPUT-1:0] to_fixed(input real val);
    real    scaled;
    integer ival;
    begin
      scaled    = val * (2.0 ** NBF_INPUT);
      ival      = $rtoi(scaled + (scaled >= 0.0 ? 0.5 : -0.5)); // redondeo
      to_fixed  = ival[NB_INPUT-1:0];
    end
  endfunction

  // ---------------- Conversion punto fijo -> real (para el log/CSV) ----------------
  function automatic real to_real(input signed [NB_OUTPUT-1:0] val);
    begin
      to_real = $itor(val) / (2.0 ** NBF_OUTPUT);
    end
  endfunction

  // ---------------- Tarea: aplica un tono senoidal de f_hz durante n_samples ----------------
  task automatic run_tone(input real f_hz, input real amp, input integer n_samples,
                           input integer fhandle, input real fs);
    real    t, val;
    integer k;
    begin
      for (k = 0; k < n_samples; k = k + 1) begin
        t   = sample_idx / fs;
        val = amp * $sin(2.0*3.14159265358979*f_hz*t);
        if(k==0)
            i_tick = 1'b1;
        
        if(k==1)
            i_tick = 1'b0;
            
        // Se fija el dato ANTES del flanco de subida (setup)
        i_is_data = to_fixed(val);
        i_en      = 1'b1;
        @(posedge clk);   // el DUT captura i_is_data / i_en aqui
        @(negedge clk);   // se espera a que la logica combinacional (prod/sum) se asiente

        $fdisplay(fhandle, "%0d,%0.6f,%0.8f,%0.8f", sample_idx, t, val, to_real(o_os_data));
        sample_idx = sample_idx + 1;
      end
    end
  endtask
  
  integer seed; 
  
  initial begin
    seed = 1;     // semilla inicial (equivalente a np.random.seed(1))
  end

  // ---------------- Estimulo principal ----------------
  initial begin
    sample_idx = 0;
    i_en       = 1'b0;
    i_is_data  = {NB_INPUT{1'b0}};
    i_srst     = 1'b1;
    repeat (5) @(posedge clk);
    i_srst = 1'b0;

    fout = $fopen("fir_tb_output.csv", "w");
    $fdisplay(fout, "sample,t_s,x_in,y_out");

    // ---- Test 1: fuera de banda, frecuencia muy baja / DC (< 0.05 Hz) ----
    i_srst = 1'b1; @(posedge clk); i_srst = 1'b0; sample_idx = 0;
    run_tone(0.0,  0.8, 1500, fout, FS);

    // ---- Test 2: dentro de la banda pasante (0.05 Hz - 0.5 Hz) ----
    i_srst = 1'b1; @(posedge clk); i_srst = 1'b0; sample_idx = 0;
    run_tone(0.2,  0.8, 1500, fout, FS);

    // ---- Test 3: fuera de banda, frecuencia alta (> 0.5 Hz) ----
    i_srst = 1'b1; @(posedge clk); i_srst = 1'b0; sample_idx = 0;
    run_tone(2.0,  0.8, 1500, fout, FS);

    // ---- Test 4: multi-tono superpuesto (verifica el filtrado simultaneo) ----
    i_srst = 1'b1; @(posedge clk); i_srst = 1'b0; sample_idx = 0;
    for (i = 0; i < 2000; i = i + 1) begin
      t2   = sample_idx / FS;
      val2 = 0.05 * ($dist_normal(seed, 0, 1000) / 1000.0)    // fuera de banda (baja)
           + 0.03*$sin(2.0*3.14159265358979*0.2 *t2)    // dentro de banda
           + 0.1*$sin(2.0*3.14159265358979*0.01*t2)
           + 1.0;   // fuera de banda (alta)

      i_is_data = to_fixed(val2);
      i_en      = 1'b1;
      @(posedge clk);
      @(negedge clk);

      $fdisplay(fout, "%0d,%0.6f,%0.8f,%0.8f", sample_idx, t2, val2, to_real(o_os_data));
      sample_idx = sample_idx + 1;
    end

    $fclose(fout);
    $display("Simulacion finalizada. Resultados en fir_tb_output.csv");
    $finish;
  end

endmodule

