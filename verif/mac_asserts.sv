module mac_asserts (
    input logic clk, rst_n, start, ready,
    input logic signed [`MAC_DATA_WIDTH-1:0] m_in, q_in,
    input logic signed [`MAC_ACC_WIDTH-1:0] product
);

    // Regla: Si hay start, ready debe bajar al siguiente ciclo
    property p_start_drops_ready;
        @(posedge clk) disable iff (!rst_n) //si reset es 0, apaga assert
        start |=> !ready;   //Operador de implicación no superpuesta, si start es 1, baja ready al siguiente ciclo
    endproperty
    assert_start_drops_ready: assert property (p_start_drops_ready);

    // Regla: Ready no debe ser X después del reset
    assert_ready_not_x: assert property (@(posedge clk) rst_n |-> !$isunknown(ready));
    // Mientras reset enabled, rdy no será 0

endmodule