/*******************************************************************************
 * NIVEL 1: TOP LEVEL - UNIDAD MAC COMPLETA
 * Este módulo integra el Multiplicador de Booth y la Unidad de Acumulación.
 ******************************************************************************/
`timescale 1ns/1ps
module mac_top #(parameter DATA_WIDTH = 16) (
    input logic clk, rst_n, start, clr_acc,
    input logic [DATA_WIDTH-1:0] m_in, q_in,
    output logic [39:0] product,
    output logic ready
);
    logic [2*DATA_WIDTH-1:0] internal_product;
    logic mult_done;

    booth_multiplier #(.DATA_WIDTH(DATA_WIDTH)) multiplicador_inst (
        .clk(clk), .rst_n(rst_n), .start(start),
        .m_in(m_in), .q_in(q_in),
        .result(internal_product), .ready(mult_done) 
    );

    accumulator_unit #(.DATA_WIDTH(16)) acumulador_inst (
        .clk(clk), .rst_n(rst_n), .clr_acc(clr_acc), .acc_en(mult_done),
        .product_in(internal_product), 
        .acc_out(product)
    );

    assign ready = mult_done;
endmodule