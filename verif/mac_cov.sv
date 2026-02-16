// mac_cov.sv - Adaptado para el MAC de Israel
module mac_cov (
    input logic clk,
    input logic rst_n,
    input logic signed [15:0] operand_a,
    input logic signed [15:0] operand_b,
    input logic [1:0]  state,        // Ajusta según los bits de tu FSM
    input logic signed [39:0] product_out,
    input logic ready
);

    // ==========================================================
    // 1. COVERGROUP PARA EL MAC
    // ==========================================================
    covergroup cg_mac @(posedge clk iff rst_n);
        option.per_instance = 1;
        option.name = "Cobertura_Funcional_MAC";

        // ------------------------------------------------
        // Cobertura de Operandos (Signos y Casos Esquina)
        // ------------------------------------------------
        cp_a: coverpoint operand_a {
            bins zero     = {0};
            bins pos_small = {[1 : 127]};
            bins pos_large = {[128 : 32767]};
            bins neg_small = {[-128 : -1]};
            bins neg_large = {[-32768 : -129]};
            bins max_pos   = {32767};
            bins max_neg   = {-32768};
        }

        cp_b: coverpoint operand_b {
            bins zero     = {0};
            bins pos      = {[1 : 32767]};
            bins neg      = {[-32768 : -1]};
        }

        // ------------------------------------------------
        // Cobertura de la FSM (Booth)
        // ------------------------------------------------
        cp_fsm: coverpoint state {
            bins IDLE   = {2'b00};
            bins LOAD   = {2'b01};
            bins CALC   = {2'b10};
            bins DONE   = {2'b11};
            illegal_bins otros = default; 
        }

        // ------------------------------------------------
        // COMBINACIONES (CROSS COVERAGE) - ¡Lo más importante!
        // ------------------------------------------------
        // ¿Probamos multiplicar Negativo x Negativo? ¿Positivo x Cero?
        a_x_b: cross cp_a, cp_b;

    endgroup

    // Instancia del grupo
    cg_mac cg_inst = new();

    // Reporte al final
    final begin
        $display("\n=== REPORTE DE COBERTURA FUNCIONAL (XCELIUM) ===");
        $display("Cobertura Operando A: %.1f%%", cg_inst.cp_a.get_coverage());
        $display("Cobertura FSM: %.1f%%", cg_inst.cp_fsm.get_coverage());
        $display("Cobertura Total: %.1f%%", cg_inst.get_coverage());
        $display("==============================================\n");
    end

endmodule

// Al final de ../mac_cov.sv

bind mac_top mac_cov u_mac_cov (
    .clk(clk),
    .rst_n(rst_n),
    .operand_a(m_in),
    .operand_b(q_in),
    .product_out(product),
    .ready(ready),
    .state(multiplicador_inst.control_unit.state) 
);
