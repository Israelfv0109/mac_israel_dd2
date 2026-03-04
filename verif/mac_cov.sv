module mac_cov (
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic signed [`MAC_DATA_WIDTH-1:0] operand_a,
    input logic signed [`MAC_DATA_WIDTH-1:0] operand_b,
    input logic [1:0]  state,
    input logic signed [`MAC_ACC_WIDTH-1:0] product_out,
    input logic ready
);

    // COVERGROUP PARA EL MAC
    covergroup cg_mac @(posedge clk iff rst_n);
        option.per_instance = 1;
        option.name = "Cobertura_Funcional_MAC";

        // Cobertura de Operandos (Signos y Casos Esquina) CORNERS DE PKG
        cp_a: coverpoint operand_a iff (state == 2'b01) {
            bins zero      = {0};
            bins pos_small = {[1 : `MAC_SMALL_POS_LIMIT]};
            bins pos_large = {[`MAC_SMALL_POS_LIMIT + 1 : `MAC_MAX_POS - 1]};
            bins neg_small = {[`MAC_SMALL_NEG_LIMIT : -1]};
            bins neg_large = {[`MAC_MAX_NEG + 1 : `MAC_SMALL_NEG_LIMIT - 1]};
            bins max_pos   = {`MAC_MAX_POS};
            bins max_neg   = {`MAC_MAX_NEG};
        }

        cp_b: coverpoint operand_b iff (state == 2'b01) {
            bins zero      = {0};
            bins pos_small = {[1 : `MAC_SMALL_POS_LIMIT]};
            bins pos_large = {[`MAC_SMALL_POS_LIMIT + 1 : `MAC_MAX_POS - 1]};
            bins neg_small = {[`MAC_SMALL_NEG_LIMIT : -1]};
            bins neg_large = {[`MAC_MAX_NEG + 1 : `MAC_SMALL_NEG_LIMIT - 1]};
            bins max_pos   = {`MAC_MAX_POS};
            bins max_neg   = {`MAC_MAX_NEG};
        }

        // Cobertura de la FSM (Booth)
        cp_fsm: coverpoint state {
            bins IDLE   = {2'b00};
            bins LOAD   = {2'b01};
            bins CALC   = {2'b10};
            bins DONE   = {2'b11};
            illegal_bins otros = default; 
        }

        // COMBINACIONES (CROSS COVERAGE)
        a_x_b: cross cp_a, cp_b iff (state == 2'b01);

    endgroup

    // Instancia del grupo
    cg_mac cg_inst = new();

    // Reporte al final
    /*final begin
        $display("\n=== REPORTE DE COBERTURA FUNCIONAL (XCELIUM) ===");
        $display("Cobertura Operando A: %.1f%%", cg_inst.cp_a.get_coverage());
        $display("Cobertura FSM: %.1f%%", cg_inst.cp_fsm.get_coverage());
        $display("Cobertura Total: %.1f%%", cg_inst.get_coverage());
        $display("==============================================\n");
    end*/

endmodule

bind mac_top mac_cov u_mac_cov (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .operand_a(m_in),
    .operand_b(q_in),
    .product_out(product),
    .ready(ready),
    .state(multiplicador_inst.control_unit.state) 
);
