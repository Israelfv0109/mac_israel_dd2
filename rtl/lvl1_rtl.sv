/*******************************************************************************
 * NIVEL 1: TOP LEVEL - UNIDAD MAC COMPLETA
 * Este módulo integra el Multiplicador de Booth y la Unidad de Acumulación.
 ******************************************************************************/
`timescale 1ns/1ps
module mac_top #(parameter DATA_WIDTH = 16) (
    input logic clk, rst_n, start, clr_acc,
    input logic [DATA_WIDTH-1:0] A_in, B_in,
    output logic [39:0] Accumulator,
    output logic ready_mac
);
    logic [2*DATA_WIDTH-1:0] internal_product;
    logic mult_done;

    booth_multiplier #(.DATA_WIDTH(DATA_WIDTH)) multiplicador_inst (
        .clk(clk), .rst_n(rst_n), .start(start),
        .m_in(A_in), .q_in(B_in),
        .result(internal_product), .ready(mult_done)
    );

    accumulator_unit #(.DATA_WIDTH(DATA_WIDTH)) acumulador_inst (
        .clk(clk), .rst_n(rst_n), .clr_acc(clr_acc), .acc_en(mult_done),
        .product_in(internal_product), .acc_out(Accumulator)
    );

    assign ready_mac = mult_done;
endmodule