module mac_asserts (
    input logic clk, rst_n, start, ready,
    input logic [15:0] m_in, q_in,
    input logic [39:0] product
);

    // Regla: Si hay start, ready debe bajar al siguiente ciclo
    property p_start_drops_ready;
        @(posedge clk) disable iff (!rst_n)
        start |=> !ready;
    endproperty
    assert_start_drops_ready: assert property (p_start_drops_ready);

    // Regla: Ready no debe ser X después del reset
    assert_ready_not_x: assert property (@(posedge clk) rst_n |-> !$isunknown(ready));

endmodule