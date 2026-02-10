`timescale 1ns/1ps

module tb_mac_top;

  // Señales Globales
  logic clk;
  logic rst_n;

  // Instancia de la INTERFAZ
  mac_if _if (clk, rst_n);

  // Conexión del DUT
  mac_top dut (
    .clk      (clk),
    .rst_n    (rst_n),
    // Conectamos el DUT a las señales internas de la interfaz
    .start    (_if.start),
    .m_in     (_if.m_in), 
    .q_in     (_if.q_in),
    .product  (_if.product),
    .ready    (_if.ready)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // PROGRAMA DE PRUEBA
  initial begin
    $display("\n========================================");
    $display("  INICIO DE SIMULACION CON INTERFACE");
    $display("========================================");

    // Paso A: inicializacion
    rst_n = 0;
    _if.initialize(); // Llamada a la tarea de la interfaz
    #20 rst_n = 1;
    $display("[TB] Reset liberado.");

    // Paso B: Pruebas

    // CASO 1: 10 * 10 = 100
    $display("\n[TB] TC1: Calculando 10 * 10...");
    _if.compute(16'd10, 16'd10); // Tarea automática: pone datos, da start, espera ready

    if (_if.product !== 40'd100) 
      $error("[FAIL] TC1: Esperaba 100, obtuve %0d", _if.product);
    else 
      $display("[PASS] TC1: Resultado correcto (100).");

    // CASO 2: Acumulación (100 + (5 * 2) = 110)
    // Nota: Como tu RTL acumula siempre, el resultado anterior (100) se suma.
    $display("\n[TB] TC2: Acumulando 5 * 2...");
    _if.compute(16'd5, 16'd2);

    if (_if.product !== 40'd110) 
      $error("[FAIL] TC2: Esperaba 110, obtuve %0d", _if.product);
    else 
      $display("[PASS] TC2: Acumulación correcta (110).");

    // CASO 3: Signos (110 + (2 * -3) = 104)
    $display("\n[TB] TC3: Restando (2 * -3)...");
    _if.compute(16'd2, -16'sd3); // -3 en complemento a 2 de 16 bits

    if (_if.product !== 40'd104) 
      $error("[FAIL] TC3: Esperaba 104, obtuve %0d", _if.product);
    else 
      $display("[PASS] TC3: Signos correctos (104).");

    // Fin
    #50;
    $display("\n========================================");
    $display("  FIN DE SIMULACION EXITOSA");
    $display("========================================");
    $finish;
  end

endmodule