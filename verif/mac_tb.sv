`timescale 1ns/1ps

// `define MAC_BASIC_FLOW_TEST 
 `define MAC_SIGNED_MIX_TEST
// `define MAC_ACCUM_LOOP_TEST
// `define MAC_ZERO_OPS_TEST 
// `define MAC_MAX_MIN_TEST 
// `define MAC_RST_MID_OP_TEST


`include "mac_pkg.sv"
`include "mac_if.sv"
`include "mac_asserts.sv"

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
        .clk(if_i.clk), .rst_n(if_i.rst_n), .clr_acc(1'b0),
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
        $display("\n=================================");
        $display("   TEST CASE 1: BASIC FLOW       ");
        $display("=================================");
        
        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();

        // 2. Multiplicación simple: 10 * 10 = 100
        $display("[TB] Calculando 10 * 10...");
        if_i.compute(16'd10, 16'd10);
        assert(if_i.product === 40'd100) else 
            $error("Fallo TC1. DUT=%0d", if_i.product);

        // 3. Acumulación: 100 + (5 * 2) = 110
        $display("[TB] Acumulando 5 * 2...");
        if_i.compute(16'd5, 16'd2);
        assert(if_i.product === 40'd110) else 
            $error("Fallo TC2. DUT=%0d", if_i.product);

        // 4. Reset on-the-fly y cálculo: 0 + (2 * 3) = 6
        $display("[TB] Reset intermedio y calculando 2 * 3...");
        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();
        
        if_i.compute(16'd2, 16'd3);
        assert(if_i.product === 40'd6) else 
            $error("Fallo TC3 (Reset manual falló). DUT=%0d", if_i.product);

        $display("\nTEST CASE 1 PASSED");
        $finish;
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
`ifdef MAC_RST_MID_OP_TEST 
    initial begin
        $display("\n=================================");
        $display("   TEST CASE 6: RESET MID-OP     ");
        $display("=================================");

        rst_n = 0;
        #20ns;
        rst_n = 1;
        if_i.initialize();

        // 1. Iniciamos una operación normal
        $display("[TB] Iniciando operación larga (100 * 100)...");
        fork
            begin
                if_i.compute(16'd100, 16'd100);
            end
            
            // Interrumpir con Reset a mitad de camino
            begin
                repeat(4) @(posedge clk); 
                $display("[TB] RESET DE EMERGENCIA! (A mitad de cálculo)");
                rst_n = 0;
                #40ns; // Mantener reset 40ns
                rst_n = 1;
                $display("[TB] Reset liberado");      
            end
        join_any // El primero que termine (reset) gana
        
        disable fork; // Detenemos el task 'compute' que se quedó esperando
        #20ns;        // Le damos tiempo al hardware de reaccionar al reset

        // 4. Verificación: El producto debe ser 0.
        if_i.initialize(); // Volver a poner señales en orden
        $display("[TB] Verificando que el acumulador esté limpio...");
        
        if (if_i.product !== 0) 
            $error("El acumulador no se limpió tras el reset mid-op. Got: %0d", if_i.product);
        else 
            $display("-> Acumulador en 0. Sistema recuperado.");

        // 5. Probar que el sistema sigue vivo tras el susto
        $display("[TB] Verificando que el sistema aún puede calcular...");
        if_i.compute(16'd2, 16'd2);
        
        if (if_i.product === 40'd4) 
            $display("-> Sistema operativo. 2 * 2 = 4");
        else 
            $error("El sistema quedó trabado tras el reset mid-op. DUT=%0d", if_i.product);

        $display("\nTEST CASE 6 PASSED");
        $finish;
    end
`endif
endmodule