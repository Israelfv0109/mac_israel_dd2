`timescale 1ns/1ps

 `define MAC_BASIC_FLOW_TEST 
// `define MAC_SIGNED_MIX_TEST
// `define MAC_ACCUM_LOOP_TEST
// `define MAC_ZERO_OPS_TEST 
// `define MAC_MAX_MIN_TEST 
// `define MAC_RST_MID_OP_TEST


`include "mac_pkg.sv"
//`include "mac_if.sv"
//`include "mac_asserts.sv"

import mac_pkg::*; // Importamos las clases

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

    // Conexión de Aserciones SVA
    bind mac_top mac_asserts asserts_inst (
        .clk(clk), .rst_n(rst_n), .start(start), 
        .ready(ready), .m_in(m_in), .q_in(q_in), .product(product)
    );

    // TEST CASE 1: BASIC FLOW
`ifdef MAC_BASIC_FLOW_TEST
    initial begin
        static logic signed [15:0] rand_a, rand_b;
        static logic signed [39:0] expected_acc = 0;

        $display("\n=================================");
        $display("    TEST CASE 1: RANDOM FLOW     ");
        $display("=================================");

        rst_n = 0; #20ns; rst_n = 1;
        if_i.initialize();

        // 1. Primera ráfaga (50 cálculos)
        $display("[TB] Iniciando primera ráfaga de 50 acumulaciones...");
        repeat(5000) begin
            rand_a = $random; rand_b = $random;
            expected_acc = expected_acc + (rand_a * rand_b);
            if_i.compute(rand_a, rand_b);
            assert(if_i.product === expected_acc) else $error("Error en acumulación");
        end

        // 2. Reset intermedio (Para limpiar y probar la FSM)
        $display("[TB] Aplicando reset manual...");
        rst_n = 0; #20ns; rst_n = 1;
        if_i.initialize();
        expected_acc = 0; 

        // 3. Segunda ráfaga (Otras 50)
        $display("[TB] Segunda ráfaga tras reset...");
        repeat(5000) begin
            rand_a = $random; rand_b = $random;
            expected_acc = expected_acc + (rand_a * rand_b);
            if_i.compute(rand_a, rand_b);
            assert(if_i.product === expected_acc) else $error("Error tras reset");
        end

        // 4. TIROS DE PRECISIÓN (Justo antes de terminar)
        $display("[TB] Ejecutando ráfaga final para 100%% de cobertura cruzada");

        // --- Cruces con CERO ---
        if_i.compute(16'd0,      16'd100);   // Bin: (zero, pos)     -> Faltaba
        if_i.compute(16'd0,     -16'd100);   // Bin: (zero, neg)     -> Faltaba
        if_i.compute(16'd5,       16'd0);    // Bin: (pos_small, zero)
        if_i.compute(-16'd5,      16'd0);    // Bin: (neg_small, zero)
        if_i.compute(16'sh7FFF,   16'd0);    // Bin: (max_pos, zero)
        if_i.compute(16'sh8000,   16'd0);    // Bin: (max_neg, zero)

        // --- Cruces con MÁXIMOS (Los más difíciles para el random) ---
        if_i.compute(16'sh7FFF,   16'd50);   // Bin: (max_pos, pos)  -> Faltaba
        if_i.compute(16'sh7FFF,  -16'd50);   // Bin: (max_pos, neg)  -> Faltaba
        if_i.compute(16'sh8000,   16'd50);   // Bin: (max_neg, pos)  -> Faltaba
        if_i.compute(16'sh8000,  -16'd50);   // Bin: (max_neg, neg)  -> Faltaba

        $display("\n[TB] ¡MISIÓN CUMPLIDA! Cobertura funcional completada.");
        $finish;

        $display("\nTEST CASE 1 PASSED (Total: 104 pruebas)");
        $finish; // EL ÚNICO $FINISH DEBE IR AQUÍ
    end
`endif

    // TEST CASE 2: SIGNED MIX (Signos Aleatorios)
`ifdef MAC_SIGNED_MIX_TEST
    random_gen rg;
    logic signed [39:0] tb_acc;
    logic signed [39:0] mult_res;

    initial begin
        rg = new();
        $display("\n=================================");
        $display("   TEST CASE 2: SIGNED MIX       ");
        $display("=================================");
        
        // Reset Limpio
        tb_acc = 40'd0;
        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();
        
        // 20 Pruebas
        repeat(20) begin
            void'(rg.randomize());
            
            // Scoreboard (Matemáticas perfectas)
            mult_res = $signed(rg.a) * $signed(rg.b);
            tb_acc += mult_res;
            
            // Enviar al Hardware
            if_i.compute(rg.a, rg.b);
            
            // El Juez
            assert(if_i.product === tb_acc) else 
                $error("BUG RTL! Entradas: A=%0d, B=%0d | Suma Esperada=%0d | DUT escupió=%0d", 
                        $signed(rg.a), $signed(rg.b), tb_acc, $signed(if_i.product));
        end
        
        $display("\nTEST CASE 2 PASSED");
        $finish;
    end
`endif

    // TEST CASE 3: ACCUM LOOP (Acumulación larga)
`ifdef MAC_ACCUM_LOOP_TEST 
    random_gen_small rg_small;
    logic signed [39:0] tb_acc;
    logic signed [39:0] mult_res;

    initial begin
        rg_small = new(); 
        $display("\n=======================================");
        $display("  TEST CASE 3: ACCUMULATION LOOP (50 Ops)");
        $display("=======================================");
        
        // 1. Reset Limpio (¡Adiós al cuelgue!)
        tb_acc = 40'd0;
        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();

        repeat(50) begin
            void'(rg_small.randomize());
            
            // Matemáticas nativas perfectas (usando rg_small)
            mult_res = $signed(rg_small.a) * $signed(rg_small.b);
            tb_acc += mult_res;
            if_i.compute(rg_small.a, rg_small.b);
            
            assert(if_i.product === tb_acc) else 
                $error("Fallo acumulador! A=%0d, B=%0d | DUT=%0d, Esperado=%0d", 
                        $signed(rg_small.a), $signed(rg_small.b), $signed(if_i.product), tb_acc);
        end
        
        $display("\nTEST CASE 3 PASSED: 50 ciclos acumulados con éxito.");
        $finish;
    end
`endif

    // TEST CASE 4: ZERO OPS (Multiplicación por Cero)
`ifdef MAC_ZERO_OPS_TEST 
    initial begin
        $display("\n=================================");
        $display("   TEST CASE 4: ZERO OPS         ");
        $display("=================================");

        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();
        
        // Cargar algo primero: 10*10 = 100
        $display("[TB] Cargando base: 10 * 10 = 100...");
        if_i.compute(16'd10, 16'd10); 

        // Multiplicar por Cero (A=0) -> Debe mantenerse en 100
        $display("[TB] Acumulando: 0 * 55...");
        if_i.compute(16'd0, 16'd55);
        assert(if_i.product === 40'd100) else $error("Fallo Mult por Cero (A). DUT=%0d", if_i.product);

        // Multiplicar por Cero (B=0) -> Debe mantenerse en 100
        $display("[TB] Acumulando: 99 * 0...");
        if_i.compute(16'd99, 16'd0);
        assert(if_i.product === 40'd100) else $error("Fallo Mult por Cero (B). DUT=%0d", if_i.product);

        $display("\nTEST CASE 4 PASSED");
        $finish;
    end
`endif

    // TEST CASE 5: MAX/MIN (Corner Cases)
`ifdef MAC_MAX_MIN_TEST
    logic signed [39:0] tb_acc;
    logic signed [39:0] mult_res;
    
    initial begin
        $display("\n=================================");
        $display("   TEST CASE 5: MAX / MIN        ");
        $display("=================================");
        
        tb_acc = 40'd0;
        rst_n = 0; #20ns; rst_n = 1;
        if_i.initialize();

        // 1. Max * Max (32767 * 32767)
        $display("[TB] Max * Max (32767 * 32767)...");
        mult_res = $signed(16'h7FFF) * $signed(16'h7FFF);
        tb_acc += mult_res;
        if_i.compute(16'h7FFF, 16'h7FFF);
        assert(if_i.product === tb_acc) else $error("Fallo Max*Max. DUT=%0d", if_i.product);

        // 2. Min * Min (-32768 * -32768)
        $display("[TB] Min * Min (-32768 * -32768)...");
        mult_res = $signed(16'h8000) * $signed(16'h8000);
        tb_acc += mult_res;
        if_i.compute(16'h8000, 16'h8000);
        assert(if_i.product === tb_acc) else $error("Fallo Min*Min. DUT=%0d", if_i.product);

        // 3. Max * Min (32767 * -32768)
        $display("[TB] Max * Min (32767 * -32768)...");
        mult_res = $signed(16'h7FFF) * $signed(16'h8000);
        tb_acc += mult_res;
        if_i.compute(16'h7FFF, 16'h8000);
        assert(if_i.product === tb_acc) else $error("Fallo Max*Min. DUT=%0d", if_i.product);

        $display("\nTEST CASE 5 PASSED");
        $finish;
    end
`endif

    // TEST CASE 6: MAC_RST_MID_OP_TEST (Reset en medio de operación)
    //sin ifdef para que se ejecute siempre, para covertura...
        // ==========================================================
        // TEST CASE 6: RESET ON-FLY
        // ==========================================================
        $display("\n[TB] =========================================");
        $display("[TB] RUNNING: TEST CASE 6 (Reset On-Fly)");
        $display("[TB] =========================================");

        if_i.start <= 1'b1;
        if_i.operand_a <= 16'h1234;
        if_i.operand_b <= 16'h5678;

        repeat(5) @(posedge clk);
        $display("[TB] @%0t ns: Interrumpiendo operación con RESET...", $time);

        if_i.rst_n <= 1'b0;
        repeat(2) @(posedge clk);
        if_i.rst_n <= 1'b1;

        @(posedge clk);
        if (if_i.ready == 0 && dut.u_mac_cov.product_out == 0) begin
            $display("[TB] @%0t ns: SUCCESS - Recuperación exitosa.", $time);
            $display("TEST CASE 6 PASSED");
        end else begin
            $display("[TB] @%0t ns: ERROR - No se recuperó bien.", $time);
            $display("TEST CASE 6 FAILED");
        end
        $display("=============================================\n");

        $finish; 
    end
endmodule
