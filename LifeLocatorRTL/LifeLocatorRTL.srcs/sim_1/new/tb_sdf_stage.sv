`timescale 1ns / 1ps
module tb_sdf_stage_final;

  localparam NB   = 18;
  localparam NBF  = 16;
  localparam DUT_D           = 16;
  localparam DUT_HAS_TWIDDLE = 1;
  localparam DUT_TW_FILE     = "tw_d16.mem";

  localparam real CLK_PERIOD = 10.0;
  localparam integer NFRAMES = 6;
  localparam integer NCYCLES = NFRAMES * 2 * DUT_D;

  reg                     clk;
  reg                     i_srst;
  reg                     i_en;
  reg  signed [NB-1:0]    i_re, i_im;
  wire signed [NB-1:0]    o_re, o_im;

  sdf_stage #(.NB(NB), .NBF(NBF), .D(DUT_D), .HAS_TWIDDLE(DUT_HAS_TWIDDLE), .TW_FILE(DUT_TW_FILE)) 
      dut (.clk(clk), .i_srst(i_srst), .i_en(i_en), .i_re(i_re), .i_im(i_im), .o_re(o_re), .o_im(o_im));

  initial clk = 1'b0;
  always #(CLK_PERIOD/2.0) clk = ~clk;

  function automatic signed [NB-1:0] to_fixed(input real val);
    to_fixed = $rtoi(val * (2.0 ** NBF))[NB-1:0];
  endfunction

  function automatic real to_real(input signed [NB-1:0] val);
    to_real = $itor(val) / (2.0 ** NBF);
  endfunction

  integer cyc;
  real    ar_real, ai_real;
  real    g_fifo_re [0:DUT_D-1];
  real    g_fifo_im [0:DUT_D-1];
  integer g_cnt;
  real    g_out_re, g_out_im;
  real    g_out_re_delayed, g_out_im_delayed;
  real    popped_re, popped_im, to_push_re, to_push_im;
  real    s_re, s_im, d_re, d_im, dtw_re, dtw_im;
  real    ang, twr, twi;
  integer j, idx;
  real    err, max_err;
  integer errors;

  initial begin
    i_srst  = 1'b1;
    i_en    = 1'b0;
    i_re    = 0;
    i_im    = 0;
    g_cnt   = 0;
    g_out_re = 0.0; g_out_im = 0.0;
    g_out_re_delayed = 0.0; g_out_im_delayed = 0.0;
    for (idx = 0; idx < DUT_D; idx++) begin
      g_fifo_re[idx] = 0.0;
      g_fifo_im[idx] = 0.0;
    end
    max_err = 0.0;
    errors  = 0;

    // Reset
    repeat (10) @(posedge clk);
    i_srst = 1'b0;
    i_en   = 1'b1;

    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      // Generar estímulo
      ar_real = 0.3*$sin(2.0*3.14159265358979*0.013*cyc) + 0.15*$cos(2.0*3.14159265358979*0.211*cyc);
      ai_real = 0.25*$sin(2.0*3.14159265358979*0.037*cyc);

      i_re = to_fixed(ar_real);
      i_im = to_fixed(ai_real);

      // --- GOLDEN (solo se actualiza cuando i_en=1) ---
      // El golden debe reflejar exactamente lo que hace el DUT,
      // incluyendo el comportamiento durante reset (no hacer nada)
      popped_re = g_fifo_re[DUT_D-1];
      popped_im = g_fifo_im[DUT_D-1];

      if (g_cnt < DUT_D) begin
        to_push_re = ar_real;
        to_push_im = ai_real;
        g_out_re   = popped_re;
        g_out_im   = popped_im;
      end else begin
        j   = g_cnt - DUT_D;
        ang = -2.0*3.14159265358979*j / (2.0*DUT_D);
        twr = $cos(ang);
        twi = $sin(ang);

        s_re = (popped_re + ar_real) / 2.0;
        s_im = (popped_im + ai_real) / 2.0;
        d_re = (popped_re - ar_real) / 2.0;
        d_im = (popped_im - ai_real) / 2.0;

        if (DUT_HAS_TWIDDLE) begin
          dtw_re = d_re*twr - d_im*twi;
          dtw_im = d_re*twi + d_im*twr;
        end else begin
          dtw_re = d_re;
          dtw_im = d_im;
        end

        to_push_re = dtw_re;
        to_push_im = dtw_im;
        g_out_re   = s_re;
        g_out_im   = s_im;
      end

      for (idx = DUT_D-1; idx >= 1; idx--) begin
        g_fifo_re[idx] = g_fifo_re[idx-1];
        g_fifo_im[idx] = g_fifo_im[idx-1];
      end
      g_fifo_re[0] = to_push_re;
      g_fifo_im[0] = to_push_im;

      g_cnt = (g_cnt == 2*DUT_D-1) ? 0 : g_cnt + 1;

      // Avanzar reloj
      @(posedge clk);

      // Comparar (DUT tiene 1 ciclo de latencia)
      if (cyc > 0) begin
        err = $sqrt((to_real(o_re) - g_out_re_delayed)**2 + (to_real(o_im) - g_out_im_delayed)**2);
        if (err > max_err) max_err = err;
        if (err > 0.02) begin
          errors++;
          if (errors <= 5) begin
            $display("MISMATCH cyc=%0d: DUT=(%0.4f,%0.4f) Golden=(%0.4f,%0.4f) err=%0.4f", 
                     cyc, to_real(o_re), to_real(o_im), g_out_re_delayed, g_out_im_delayed, err);
          end
        end
      end
      g_out_re_delayed = g_out_re;
      g_out_im_delayed = g_out_im;
    end

    $display("Error max: %0.6f, Mismatches: %0d", max_err, errors);
    $display(errors == 0 ? "PASS" : "FAIL");
    $finish;
  end

endmodule

