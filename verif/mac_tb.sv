`timescale 1ns/1ps

//`define MAC_BASIC_FLOW_TEST
// `define MAC_SIGNED_MIX_TEST
// `define MAC_ACCUM_LOOP_TEST
// `define MAC_ZERO_OPS_TEST
// `define MAC_MAX_MIN_TEST
// `define MAC_RST_MID_OP_TEST
 `define MAC_CORNERS_TEST

`include "mac_pkg.sv"
//`include "mac_if.sv"
//`include "mac_asserts.sv"

import mac_pkg::*;

module mac_tb;
    logic clk;
    logic rst_n;

    // Generador de Reloj Global
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Instancia de Interfaz y DUT
    mac_if if_i(clk, rst_n);
    mac_top dut (
        .clk(if_i.clk), .rst_n(if_i.rst_n),
        .start(if_i.start), .m_in(if_i.m_in), .q_in(if_i.q_in),
        .ready(if_i.ready), .product(if_i.product)
    );

    // Conexión de Aserciones
    bind mac_top mac_asserts asserts_inst (
        .clk(clk), .rst_n(rst_n), .start(start),
        .ready(ready), .m_in(m_in), .q_in(q_in), .product(product)
    );

    // TEST CASE 1: BASIC FLOW
`ifdef MAC_BASIC_FLOW_TEST
    initial begin
    static logic signed [`MAC_DATA_WIDTH-1:0] rand_a, rand_b;
    static logic signed [`MAC_ACC_WIDTH-1:0] expected_acc = 0;

        $display("=================================");
        $display("TEST CASE 1: RANDOM FLOW");
        $display("=================================");

        rst_n = 0; #20ns; rst_n = 1;
        if_i.initialize();

        // Primera ráfaga (500mil cálculos)
        $display("Iniciando primera ráfaga de 500mil acumulaciones...");
        repeat(500000) begin
            rand_a = $random; rand_b = $random;
            expected_acc = expected_acc + ($signed(rand_a) * $signed(rand_b));
            if_i.compute(rand_a, rand_b);
            assert(if_i.product === expected_acc) else $error("Error en acumulación");
        end

        // Reset intermedio (Para limpiar y probar la FSM)
        $display("Aplicando reset manual...");
        rst_n = 0; #20ns; rst_n = 1;
        if_i.initialize();
        expected_acc = 0;

        // Segunda ráfaga (otros 500mil calculos)
        $display("Segunda ráfaga tras reset");
        repeat(500000) begin
            rand_a = $random; rand_b = $random;
            expected_acc = expected_acc + ($signed(rand_a) * $signed(rand_b));
            if_i.compute(rand_a, rand_b);
            assert(if_i.product === expected_acc) else $error("Error tras reset");
        end

        $display("TEST CASE 1 PASSED (Total: 1millon de pruebas)");
    
        // ==========================================================
        // TEST CASE 6: RESET ON-FLY (Dentro del bloque del Test 1)
        // ==========================================================
        $display("=========================================");
        $display("RUNNING: TEST CASE 6 (Reset On-Fly)");
        $display("=========================================");

        if_i.start <= 1'b1;
        if_i.m_in <= 32'h1234;
        if_i.q_in <= 32'h5678;

        repeat(5) @(posedge clk);
        $display("@%0t ns: Interrumpiendo operación con RESET...", $time);

        rst_n = 1'b0; 
        repeat(2) @(posedge clk);
        rst_n = 1'b1; 

        @(posedge clk);
        if (if_i.ready == 0 && if_i.product == 0) begin
            $display("@%0t ns: SUCCESS - Recuperación exitosa.", $time);
            $display("TEST CASE 6 PASSED");
        end else begin
            $display("@%0t ns: ERROR - No se recuperó bien.", $time);
            $display("TEST CASE 6 FAILED");
        end
        $display("=============================================\n");

        $finish;    
    end
`endif

    // TEST CASE 2: SIGNED MIX (Signos Aleatorios)
`ifdef MAC_SIGNED_MIX_TEST
    random_gen rg;
    logic signed [`MAC_ACC_WIDTH-1:0] tb_acc;
    logic signed [`MAC_ACC_WIDTH-1:0] mult_res;

    initial begin
        rg = new();
        $display("=================================");
        $display("TEST CASE 2: SIGNED MIX");
        $display("=================================");

        // Reset Limpio
        tb_acc = '0;
        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();

        // 1 millon Pruebas
        repeat(1000000) begin
            void'(rg.randomize());

            // Scoreboard
            mult_res = $signed(rg.a) * $signed(rg.b);
            tb_acc += mult_res;

            // Enviar al Hardware
            if_i.compute(rg.a, rg.b);

            // El Juez
            assert(if_i.product === tb_acc) else
                $error("ERROR Entradas: A=%0d, B=%0d | Suma Esperada=%0d | DUT escupió=%0d",
                        $signed(rg.a), $signed(rg.b), tb_acc, $signed(if_i.product));
        end

        $display("TEST CASE 2 PASSED");
        $finish;
    end
`endif

    // TEST CASE 3: ACCUM LOOP (Acumulación larga)
`ifdef MAC_ACCUM_LOOP_TEST
    random_gen_small rg_small;
    logic signed [`MAC_ACC_WIDTH-1:0] tb_acc;
    logic signed [`MAC_ACC_WIDTH-1:0] mult_res;

    initial begin
        rg_small = new();
        $display("=======================================");
        $display("TEST CASE 3: ACCUMULATION LOOP");
        $display("=======================================");

        // 1. Reset Limpio
        tb_acc = '0;
        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();

        // 1 millon Pruebas
        repeat(1000000) begin
            void'(rg_small.randomize());

            // Matemáticas nativas perfectas
            mult_res = $signed(rg_small.a) * $signed(rg_small.b);
            tb_acc += mult_res;
            if_i.compute(rg_small.a, rg_small.b);

            assert(if_i.product === tb_acc) else
                    $error("Fallo acumulador! A=%0d, B=%0d | DUT=%0d, Esperado=%0d",
                        $signed(rg_small.a), $signed(rg_small.b), $signed(if_i.product), tb_acc);
        end

        $display("TEST CASE 3 PASSED: 1 millon ciclos acumulados con éxito.");
        $finish;
    end
`endif

    // TEST CASE 4: ZERO OPS (Multiplicación por Cero)
`ifdef MAC_ZERO_OPS_TEST
    initial begin
        $display("=================================");
        $display("TEST CASE 4: ZERO OPS");
        $display("=================================");

        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();

        // Cargar algo primero: 10*10 = 100
        $display("Cargando base: 10 * 10 = 100...");
        if_i.compute(32'd10, 32'd10);

        // Multiplicar por Cero (A=0) -> Debe mantenerse en 100
        $display("Acumulando: 0 * 55...");
        if_i.compute(32'd0, 32'd55);
        assert(if_i.product === 64'd100) else $error("Fallo Mult por Cero (A). DUT=%0d", if_i.product);

        // Multiplicar por Cero (B=0) -> Debe mantenerse en 100
        $display("Acumulando: 99 * 0...");
        if_i.compute(32'd99, 32'd0);
        assert(if_i.product === 64'd100) else $error("Fallo Mult por Cero (B). DUT=%0d", if_i.product);

        $display("\nTEST CASE 4 PASSED");
        $finish;
    end
`endif

    // TEST CASE 5: MAX/MIN (Corner Cases)
`ifdef MAC_MAX_MIN_TEST
    logic signed [`MAC_ACC_WIDTH-1:0] tb_acc;
    logic signed [`MAC_ACC_WIDTH-1:0] mult_res;

    initial begin
        $display("=================================");
        $display("TEST CASE 5: MAX / MIN");
        $display("=================================");

        tb_acc = '0;
        rst_n = 0; #20ns; rst_n = 1;
        if_i.initialize();

        // 1. Max * Max
        $display("Max * Max...");
        mult_res = $signed(`MAC_MAX_POS) * $signed(`MAC_MAX_POS);
        tb_acc += mult_res;
        if_i.compute(`MAC_MAX_POS, `MAC_MAX_POS);
        assert(if_i.product === tb_acc) else $error("Fallo Max*Max. DUT=%0d", if_i.product);

        // 2. Min * Min
        $display("Min * Min...");
        mult_res = $signed(`MAC_MAX_NEG) * $signed(`MAC_MAX_NEG);
        tb_acc += mult_res;
        if_i.compute(`MAC_MAX_NEG, `MAC_MAX_NEG);
        assert(if_i.product === tb_acc) else $error("Fallo Min*Min. DUT=%0d", if_i.product);

        // 3. Max * Min
        $display("Max * Min...");
        mult_res = $signed(`MAC_MAX_POS) * $signed(`MAC_MAX_NEG);
        tb_acc += mult_res;
        if_i.compute(`MAC_MAX_POS, `MAC_MAX_NEG);
        assert(if_i.product === tb_acc) else $error("Fallo Max*Min. DUT=%0d", if_i.product);

        $display("TEST CASE 5 PASSED");
        $finish;
    end
`endif

    // TEST CASE 7: CORNER CASES AUTOMÁTICOS
`ifdef MAC_CORNERS_TEST
    random_gen_corners rg_corners;
    logic signed [`MAC_ACC_WIDTH-1:0] tb_acc;
    logic signed [`MAC_ACC_WIDTH-1:0] mult_res;

    initial begin
        rg_corners = new();
        $display("=======================================");
        $display("TEST CASE 7: CORNER CASES");
        $display("=======================================");

        // Reset Limpio
        tb_acc = '0;
        rst_n = 0; #20ns; rst_n = 1;
        if_i.initialize();

        $display("Dispara 500mil tiros");
        repeat(500000) begin
            void'(rg_corners.randomize());

            // Scoreboard Matemático
            mult_res = $signed(rg_corners.a) * $signed(rg_corners.b);
            tb_acc += mult_res;

            // Enviar al Hardware
            if_i.compute(rg_corners.a, rg_corners.b);

            // El Juez
            assert(if_i.product === tb_acc) else
                $error("Fallo Corner Case: A=%0d, B=%0d | DUT=%0d | ESPERADO=%0d", 
                        $signed(rg_corners.a), $signed(rg_corners.b), $signed(if_i.product), tb_acc);
        end

        $display("TEST CASE 7 PASSED");
        $finish;
    end
`endif

endmodule