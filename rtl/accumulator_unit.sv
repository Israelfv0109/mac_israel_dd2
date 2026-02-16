`timescale 1ns/1ps

module accumulator_unit #(parameter DATA_WIDTH = 16) (
    input  logic clk, rst_n, acc_en,
    input  logic [2*DATA_WIDTH-1:0] product_in,
    output logic [39:0] acc_out
);
    logic [39:0] current_sum, acc_reg;
    logic [39:0] product_ext;

    // Extensión de signo segura (toma el bit MSB del producto)
    assign product_ext = { {(40-(2*DATA_WIDTH)){product_in[2*DATA_WIDTH-1]}}, product_in };

    // Instancia del sumador de 40 bits
    adder_40bit mac_adder (.a(product_ext), .b(acc_reg), .sum(current_sum));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         acc_reg <= 40'b0;
        else if (acc_en)    acc_reg <= current_sum;
    end

    assign acc_out = acc_reg;
endmodule
