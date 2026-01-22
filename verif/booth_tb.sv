/*******************************************************************************
 * MODULO: tb_booth_multiplier
 ******************************************************************************/
`timescale 1ns/1ps

module tb_booth_multiplier;
    // --- PARAMETROS DE LA PRUEBA ---
    localparam DATA_WIDTH = 9;
    localparam DELAY = 10; // Retardo entre cada caso de prueba (en ns)
    // --- SEÑALES PARA CONECTAR AL (DUT) ---
    logic signed [DATA_WIDTH-1:0]   multiplicando;
    logic signed [DATA_WIDTH-1:0]   multiplicador;
    logic signed [2*DATA_WIDTH-1:0] resultado;
    logic                           flag;
    // --- INSTANCIA DEL DISEÑO BAJO PRUEBA (DUT) ---
    booth_multiplier #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .multiplicando_in(multiplicando),
        .multiplicador_in(multiplicador),
        .resultado_out(resultado),
        .flag_out(flag)
    );
    //*************************************************************************************************
    initial begin
        $display("*********** Iniciando Simulacion de casos ***********");

        // --- Caso inicial 0*0 ---
        multiplicando = 0;
        multiplicador = 0;
        #(DELAY);
        $display("*********** Caso inicial 0*0 ************************");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);
        
        // --- Prueba 1: Positivo * Positivo ---
        multiplicando = 3;
        multiplicador = 2;
        #(DELAY);
        $display("*********** Prueba 1: Positivo * Positivo ***********");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);

        // --- Prueba 2: Positivo * Negativo ---
        multiplicando = 3;
        multiplicador = -2;
        #(DELAY);
        $display("*********** Prueba 2: Positivo * Negativo ***********");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);

        // --- Prueba 3: Negativo * Positivo ---
        multiplicando = -3;
        multiplicador = 2;
        #(DELAY);
        $display("*********** Prueba 3: Negativo * Positivo ***********");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);

        // --- Prueba 4: Negativo * Negativo ---
        multiplicando = -3;
        multiplicador = -2;
        #(DELAY);
        $display("*********** Prueba 4: Negativo * Negativo ***********");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);
        
        // --- Prueba 5: Limite positivo * -1 ---
        multiplicando = 7;
        multiplicador = -1;
        #(DELAY);
        $display("*********** Prueba 5: Limite positivo * -1 **********");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);

        // --- Prueba 6: Limite negativo (caso critico) ---
        multiplicando = -8;
        multiplicador = 7;
        #(DELAY);
        $display("*********** Prueba 6: Limite negativo ***************");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);

        // --- Prueba 7: Multiplicacion por cero ---
        multiplicando = 5;
        multiplicador = 0;
        #(DELAY);
        $display("*********** Prueba 7: Multiplicacion por cero *******");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);

        // --- Prueba 8: Cero por un numero ---
        multiplicando = 0;
        multiplicador = -5;
        #(DELAY);
        $display("*********** Prueba 8: Cero por un numero ************");
        assert(resultado == multiplicando*multiplicador) 
            $display("MATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador); 
        else 
            $error("MISSMATCH: m : %d * q : %d, rtl: %d, tb: %d", multiplicando, multiplicador, resultado, multiplicando*multiplicador);
        
        $display("*****************************************************");
        $display("************** Simulacion Finalizada ****************");
        $finish;
    end
endmodule
/* casos de prueba
        (3, 2);    // Prueba 1: Positivo * Positivo
        (3, -2);   // Prueba 2: Positivo * Negativo
        (-3, 2);   // Prueba 3: Negativo * Positivo
        (-3, -2);  // Prueba 4: Negativo * Negativo
        (7, -1);   // Prueba 5: Limite positivo * -1
        (-8, 7);   // Prueba 6: Limite negativo (caso critico)
        (5, 0);    // Prueba 7: Multiplicacion por cero
        (0, -5);   // Prueba 8: Cero por un numero */