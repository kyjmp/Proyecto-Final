`timescale 1ns/1ps
// =============================================================================
// tb_goertzel_band_analyzer.sv
//
// Testbench para Vivado (usar como "simulation source", tipo SystemVerilog).
// Genera un tono sintético en Q2.16 a una de las frecuencias de la banda
// (por defecto 0.2 Hz -> bin_idx = 1) muestreado a Fs = 20 Hz, se lo
// entrega al DUT y se imprimen por consola las 5 magnitudes al cierre
// del bloque.
//
// NOTA: entre muestra y muestra NO se espera el tiempo real de 50 ms
// (eso haría la simulación carísima); alcanza con esperar la cantidad
// de ciclos de reloj que la FSM necesita para procesar la muestra
// (2 ciclos * NBINS) + margen. La correctitud del algoritmo no depende
// del tiempo real entre muestras, solo del orden de las operaciones.
// =============================================================================

module tb_goertzel_band_analyzer;

    // ---------------------------------------------------------------
    // Parámetros (deben coincidir con el DUT)
    // ---------------------------------------------------------------
    localparam integer DATA_WIDTH = 18;
    localparam integer COEF_WIDTH = 18;
    localparam integer FRAC_BITS  = 16;
    localparam integer ACC_WIDTH  = 32;
    localparam integer NBINS      = 5;
    localparam integer N          = 200;
    localparam integer MAG_WIDTH  = 2*ACC_WIDTH + 2 - FRAC_BITS;
    localparam integer BAND_WIDTH = MAG_WIDTH + 4;

    localparam real FS       = 20.0;   // Hz
    localparam real TEST_FREQ = 0.3;   // Hz -> debería "pegar" en bin_idx = 1
    localparam real TEST_AMP  = 0.5;   // amplitud, en unidades reales (< 2.0)

    // margen de ciclos de clk entre muestra y muestra (>= 2*NBINS)
    localparam integer CYCLES_PER_SAMPLE = 30;

    // ---------------------------------------------------------------
    // Señales
    // ---------------------------------------------------------------
    reg                          clk;
    reg                          i_srst;
    reg                          sample_valid;
    reg  signed [DATA_WIDTH-1:0] x_in;

    wire                          mag_valid;
    wire [2:0]                    mag_bin_idx;
    wire signed [MAG_WIDTH-1:0]   mag2;
    //wire                          band_energy_valid;
    //wire signed [BAND_WIDTH-1:0]  band_energy;
    wire                          block_done;

    real mag2_real [0:NBINS-1];
    real band_energy_real;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    goertzel_algorithm #(
        .DATA_WIDTH (DATA_WIDTH),
        .COEF_WIDTH (COEF_WIDTH),
        .FRAC_BITS  (FRAC_BITS),
        .ACC_WIDTH  (ACC_WIDTH),
        .NBINS      (NBINS),
        .N          (N)
    ) dut (
        .clk               (clk),
        .i_srst             (i_srst),
        .sample_valid      (sample_valid),
        .x_in              (x_in),
        .mag_valid         (mag_valid),
        .mag_bin_idx       (mag_bin_idx),
        .mag2              (mag2),
        .block_done        (block_done)
    );

    // ---------------------------------------------------------------
    // Clock: 100 MHz (10 ns) -- el valor exacto no importa para el
    // funcionamiento, solo hay que dejar suficientes ciclos por muestra
    // ---------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Conversión real -> Q2.16 signed (18 bits), con redondeo
    // ---------------------------------------------------------------
    function automatic signed [DATA_WIDTH-1:0] to_q2_16(input real val);
        real scaled;
        integer temp;
        begin
            scaled = val * (1 << FRAC_BITS);
            if (scaled >= 0.0)
                temp = $rtoi(scaled + 0.5);
            else
                temp = $rtoi(scaled - 0.5);
            to_q2_16 = temp[DATA_WIDTH-1:0];
        end
    endfunction

    // conversión inversa, para imprimir resultados en punto flotante
    function automatic real from_qfmt(input integer bw, input logic signed [63:0] val);
        begin
            from_qfmt = $itor(val) / (1 << FRAC_BITS);
        end
    endfunction

    // ---------------------------------------------------------------
    // Captura de resultados: guarda cada magnitud en su índice de bin
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (mag_valid) begin
            mag2_real[mag_bin_idx] <= from_qfmt(MAG_WIDTH, mag2);
            $display("[t=%0t] bin_idx=%0d (f=%0.1f Hz)  mag2 = %0d  (~%f en punto flotante)",
                       $time, mag_bin_idx, 0.1*(mag_bin_idx+1), mag2, from_qfmt(MAG_WIDTH, mag2));
        end
        //if (band_energy_valid) begin
        //    band_energy_real <= from_qfmt(BAND_WIDTH, band_energy);
        //    $display("[t=%0t] *** band_energy total = %0d (~%f) ***",
        //               $time, band_energy, from_qfmt(BAND_WIDTH, band_energy));
        //end
        if (block_done) begin
            $display("[t=%0t] === BLOQUE COMPLETO (N=%0d muestras) ===", $time, N);
        end
    end

    // ---------------------------------------------------------------
    // Generación de estímulo: tono sintético a TEST_FREQ, N muestras
    // ---------------------------------------------------------------
    integer n_idx;
    real    t_sec;
    real    sample_val;
    
    integer veces = 5*N;

    initial begin
        i_srst        = 1'b1;
        sample_valid = 1'b0;
        x_in         = '0;

        repeat (5) @(posedge clk);
        i_srst = 1'b0;
        repeat (5) @(posedge clk);

        $display("Enviando %0d muestras de un tono de %0.2f Hz (amplitud %0.2f) a Fs=%0.1f Hz...",
                   N, TEST_FREQ, TEST_AMP, FS);
                   

        for (n_idx = 0; n_idx < N; n_idx = n_idx + 1) begin
            t_sec      = n_idx / FS;
            sample_val = TEST_AMP * $cos(2.0 * 3.14159265358979 * TEST_FREQ * t_sec);

            @(posedge clk);
            x_in         <= to_q2_16(sample_val);
            sample_valid <= 1'b1;
            @(posedge clk);
            sample_valid <= 1'b0;

            // esperar a que la FSM termine de procesar esta muestra
            // (2 ciclos * NBINS + margen) antes de mandar la próxima
            repeat (CYCLES_PER_SAMPLE - 2) @(posedge clk);
        end

        $display("Todas las muestras enviadas, esperando resultados del bloque...");

        // esperar a que se calculen y emitan las 5 magnitudes
        wait (block_done);
        repeat (10) @(posedge clk);

        $display("---------------------------------------------------------");
        $display("Resumen final (deberia verse un pico en el bin de %0.1f Hz):", TEST_FREQ);
        for (n_idx = 0; n_idx < NBINS; n_idx = n_idx + 1) begin
            $display("  bin %0d (%0.1f Hz) -> %f", n_idx, 0.1*(n_idx+1), mag2_real[n_idx]);
        end
        $display("---------------------------------------------------------");

$display("Enviando %0d muestras de un tono de %0.2f Hz (amplitud %0.2f) a Fs=%0.1f Hz...",
                   N, TEST_FREQ, TEST_AMP, FS);
                   

        for (n_idx = 0; n_idx < N; n_idx = n_idx + 1) begin
            t_sec      = n_idx / FS;
            sample_val = TEST_AMP * $cos(2.0 * 3.14159265358979 * TEST_FREQ * t_sec);

            @(posedge clk);
            x_in         <= to_q2_16(sample_val);
            sample_valid <= 1'b1;
            @(posedge clk);
            sample_valid <= 1'b0;

            // esperar a que la FSM termine de procesar esta muestra
            // (2 ciclos * NBINS + margen) antes de mandar la próxima
            repeat (CYCLES_PER_SAMPLE - 2) @(posedge clk);
        end

        $display("Todas las muestras enviadas, esperando resultados del bloque...");

        // esperar a que se calculen y emitan las 5 magnitudes
        wait (block_done);
        repeat (10) @(posedge clk);

        $display("---------------------------------------------------------");
        $display("Resumen final (deberia verse un pico en el bin de %0.1f Hz):", TEST_FREQ);
        for (n_idx = 0; n_idx < NBINS; n_idx = n_idx + 1) begin
            $display("  bin %0d (%0.1f Hz) -> %f", n_idx, 0.1*(n_idx+1), mag2_real[n_idx]);
        end
        $display("---------------------------------------------------------");



        $finish;
    end

    // watchdog por si algo se cuelga
    initial begin
        #5_000_000; // 5 ms de tiempo de simulación como tope
        $display("ERROR: TIMEOUT - la simulacion no termino a tiempo");
        $finish;
    end

endmodule