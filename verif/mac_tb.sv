`timescale 1ns/1ps

module tb_mac_top();

    // --- Parámetros y Señales ---
    parameter DATA_WIDTH = 16;
    logic clk;
    logic rst_n;
    logic start;
    logic clr_acc;
    logic [DATA_WIDTH-1:0] A_in;
    logic [DATA_WIDTH-1:0] B_in;
    logic [39:0] Accumulator;
    logic ready_mac;

    // --- Instancia de la Unidad MAC (DUT) ---
    mac_top #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .clr_acc(clr_acc),
        .A_in(A_in),
        .B_in(B_in),
        .Accumulator(Accumulator),
        .ready_mac(ready_mac)
    );

    // --- Generación de Reloj (100 MHz) ---
    always #5 clk = ~clk;

    // --- Tarea para realizar una multiplicación ---
    task automatic multiply_and_add(input logic signed [15:0] a, input logic signed [15:0] b);
        begin
            A_in = a;
            B_in = b;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            wait(ready_mac == 1);
            @(posedge clk); // <--- AGREGA ESTO: Espera un ciclo para que el acumulador guarde el resultado
            $display("[MAC] Multiplicacion: %d * %d terminada. Acumulado parcial: %d", a, b, $signed(Accumulator));
        end
    endtask

    // --- Proceso de Estímulos ---
    initial begin
        // Inicialización
        clk = 0;
        rst_n = 0;
        start = 0;
        clr_acc = 0;
        A_in = 0;
        B_in = 0;

        $display("--------------------------------------------------");
        $display("INICIANDO PRUEBA DE UNIDAD MAC");
        $display("--------------------------------------------------");

        // Reset del Sistema
        #20 rst_n = 1;
        #10 clr_acc = 1; // Limpiamos el acumulador al inicio
        #10 clr_acc = 0;
        #10;

        // Caso 1: 10 * 5 = 50
        multiply_and_add(16'd10, 16'd5);

        // Caso 2: 2 * -3 = -6 (Acumulado debería ser 44)
        multiply_and_add(16'd2, -16'd3);

        // Caso 3: 100 * 10 = 1000 (Acumulado debería ser 1044)
        multiply_and_add(16'd100, 16'd10);

        // Verificación Final
        #20;
        if (Accumulator == 40'd1044) begin
            $display("--------------------------------------------------");
            $display("PRUEBA EXITOSA Resultado Final: %d", $signed(Accumulator));
            $display("--------------------------------------------------");
        end else begin
            $display("--------------------------------------------------");
            $display("ERROR: Resultado esperado 1044, obtenido %d", $signed(Accumulator));
            $display("--------------------------------------------------");
        end

        #50 $finish;
    end

endmodule