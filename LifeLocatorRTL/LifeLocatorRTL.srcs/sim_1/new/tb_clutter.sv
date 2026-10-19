`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_clutter
// DUT       : filtro_clutter
//
// Genera directamente con $sin (sin archivos externos):
//   bpm     = 10
//   f_resp  = bpm/60                          -> 0.1667 Hz
//   resp    = 0.05*sin(2*pi*f_resp*t)
//   dc      = 10.0
//   drift   = 0.25*sin(2*pi*0.01*t)
//   clutter = dc + drift
//   x[n]    = clutter + resp
//
// NOTA: dc=10 no entra en el rango de Q2.16 (NB_INPUT=18, NBF_INPUT=16 -> +-2.0),
// asi que la senal se escala por SCALE=0.18 antes de cuantizar. La salida se
// vuelve a llevar a las unidades originales dividiendo por ese mismo SCALE.
//////////////////////////////////////////////////////////////////////////////////

module tb_clutter;

  // ---------------- Parametros (deben coincidir con el DUT) ----------------
  localparam NB_ALPHA   = 18;
  localparam NBF_ALPHA  = 16;
  localparam NB_INPUT   = 18;
  localparam NBF_INPUT  = 16;
  localparam NB_OUTPUT  = 18;
  localparam NBF_OUTPUT = 16;

  localparam real CLK_PERIOD = 10.0;   // ns, arbitrario (solo mueve la logica)
  localparam real FS         = 20.0;   // Hz, frecuencia de muestreo
  localparam real SCALE      = 0.18;   // escala para que dc=10 entre en +-2.0 (Q2.16)
  localparam integer N_SAMPLES = 1200; // 60 s a 20 Hz

  // ---------------- Senales ----------------
  reg                          clk;
  reg                          i_srst;
  reg                          i_en;
  reg  signed [NB_INPUT -1:0]  i_is_data;
  wire signed [NB_OUTPUT-1:0]  o_os_data;

  integer sample_idx;
  integer fout;

  // ---------------- DUT ----------------
  filtro_clutter dut (
    .o_os_data (o_os_data),
    .i_is_data (i_is_data),
    .i_en      (i_en),
    .i_srst    (i_srst),
    .clk       (clk)
  );

  // ---------------- Reloj ----------------
  initial clk = 1'b0;
  always #(CLK_PERIOD/2.0) clk = ~clk;

  // ---------------- Conversion real -> punto fijo Q2.16 ----------------
  function automatic signed [NB_INPUT-1:0] to_fixed(input real val);
    real    scaled;
    integer ival;
    begin
      scaled   = val * (2.0 ** NBF_INPUT);
      ival     = $rtoi(scaled + (scaled >= 0.0 ? 0.5 : -0.5)); // redondeo
      to_fixed = ival[NB_INPUT-1:0];
    end
  endfunction

  // ---------------- Conversion punto fijo -> real (deshace SCALE) ----------------
  function automatic real to_real_unscaled(input signed [NB_OUTPUT-1:0] val);
    begin
      to_real_unscaled = ($itor(val) / (2.0 ** NBF_OUTPUT)) / SCALE;
    end
  endfunction

  // ---------------- Estimulo principal ----------------
  
  integer seed;   // declarar afuera del loop, junto a las demas variables

  initial begin
    seed = 1;     // semilla inicial (equivalente a np.random.seed(1))
  end
  
  initial begin
    real t, bpm, f_resp, resp, dc, drift, clutter, noise, x;

    bpm = 10.0;
    f_resp = bpm/60.0;
    dc = 2.0;

    sample_idx = 0;
    i_en       = 1'b0;
    i_is_data  = {NB_INPUT{1'b0}};
    i_srst     = 1'b1;
    repeat (5) @(posedge clk);
    i_srst = 1'b0;

    fout = $fopen("clutter_tb_output.csv", "w");
    $fdisplay(fout, "sample,t_s,x_in,y_out");

    for (sample_idx = 0; sample_idx < N_SAMPLES; sample_idx = sample_idx + 1) begin
      t       = sample_idx / FS;
      resp    = 0.09*$sin(2.0*3.14159265358979*f_resp*t);
      drift   = 0.06*$sin(2.0*3.14159265358979*0.01*t);
      noise = 0.05 * ($dist_normal(seed, 0, 1000) / 1000.0);
      clutter = dc + drift+ noise;
      x       = clutter + resp;

      // Se fija el dato ANTES del flanco de subida (setup)
      i_is_data = to_fixed(x*SCALE);
      i_en      = 1'b1;
      @(posedge clk);   // el DUT captura i_is_data / i_en aqui
      @(negedge clk);   // se espera a que la logica combinacional se asiente

      $fdisplay(fout, "%0d,%0.6f,%0.8f,%0.8f", sample_idx, t, x, to_real_unscaled(o_os_data));
    end

    $fclose(fout);
    $display("Simulacion finalizada. Resultados en clutter_tb_output.csv");
    $finish;
  end

endmodule
