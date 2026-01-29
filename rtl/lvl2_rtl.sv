/*******************************************************************************
 * NIVEL 2: MÓDULOS FUNCIONALES
 * Este archivo agrupa la lógica secuencial del multiplicador y la gestión
 * de la memoria del acumulador.
 ******************************************************************************/
`timescale 1ns/1ps

module booth_multiplier #(parameter DATA_WIDTH = 16) (
    input  logic clk, rst_n, start,
    input  logic [DATA_WIDTH-1:0] m_in, q_in,
    output logic [2*DATA_WIDTH-1:0] result,
    output logic ready
);
    logic load, shift, op_sel;

    booth_fsm #(.DATA_WIDTH(DATA_WIDTH)) control_unit (
        .clk(clk), .rst_n(rst_n), .start(start),
        .load(load), .shift(shift), .op_sel(op_sel), .ready(ready)
    );

    booth_datapath #(.DATA_WIDTH(DATA_WIDTH)) arithmetic_unit (
        .clk(clk), .rst_n(rst_n), .m_in(m_in), .q_in(q_in),
        .load(load), .shift(shift), .op_sel(op_sel), .product(result)
    );
endmodule

module accumulator_unit #(parameter DATA_WIDTH = 16) (
    input  logic clk, rst_n, clr_acc, acc_en,
    input  logic [2*DATA_WIDTH-1:0] product_in,
    output logic [39:0] acc_out
);
    logic [39:0] current_sum, acc_reg;
    logic [39:0] product_ext;

    // Extensión de signo segura (toma el bit MSB del producto)
    assign product_ext = { {(40-(2*DATA_WIDTH)){product_in[2*DATA_WIDTH-1]}}, product_in };

    adder_40bit mac_adder (.a(product_ext), .b(acc_reg), .sum(current_sum));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)      acc_reg <= 40'b0;
        else if (clr_acc) acc_reg <= 40'b0;
        else if (acc_en)  acc_reg <= current_sum;
    end

    assign acc_out = acc_reg;
endmodule