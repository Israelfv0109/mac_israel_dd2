`timescale 1ns/1ps

// `include "mac_defs.svh" 

module wb_mac #(
    parameter AW = 16,
    parameter DW = 32
) (
    input  logic          clk,
    input  logic          rst_n,

    // Puerto Wishbone Esclavo
    input  logic [AW-1:0] wbs_adr_i,
    input  logic [DW-1:0] wbs_dat_i,
    output logic [DW-1:0] wbs_dat_o,
    input  logic          wbs_we_i,
    input  logic [3:0]    wbs_sel_i,
    input  logic          wbs_stb_i,
    input  logic          wbs_cyc_i,
    output logic          wbs_ack_o,
    output logic          wbs_err_o
);

    // Señales internas para conectar a la MAC
    logic signed [`MAC_DATA_WIDTH-1:0] reg_m_in;
    logic signed [`MAC_DATA_WIDTH-1:0] reg_q_in;
    logic signed [`MAC_ACC_WIDTH:0]    mac_product;
    logic mac_start;
    logic mac_ready;
    logic status_ready;

    mac_top u_mac (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (mac_start),
        .m_in    (reg_m_in),
        .q_in    (reg_q_in),
        .product (mac_product),
        .ready   (mac_ready)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            status_ready <= 1'b0;
        else if (mac_start)
            status_ready <= 1'b0; // Limpia rdy al iniciar
        else if (mac_ready)
            status_ready <= 1'b1; // Atrapa el pulso al terminar
    end

    // Decodificador del Mapa de Memoria
    // 0x00: Escribir Operando M
    // 0x04: Escribir Operando Q
    // 0x08: Escribir un 1 para dar Start (pulso automático)
    // 0x0C: Leer el bit de Ready (0 = ocupado, 1 = listo)
    // 0x10: Leer Resultado (Bits 31:0)
    // 0x14: Leer Resultado (Bits 63:32)
    // 0x18: Leer Resultado (Bits extra del acumulador, si los hay)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wbs_ack_o <= 1'b0;
            wbs_dat_o <= '0;
            reg_m_in  <= '0;
            reg_q_in  <= '0;
            mac_start <= 1'b0;
        end else begin
            wbs_ack_o <= 1'b0;
            mac_start <= 1'b0;

            if (wbs_cyc_i && wbs_stb_i && !wbs_ack_o) begin
                wbs_ack_o <= 1'b1; // Respondemos a la petición

                if (wbs_we_i) begin
                    // ESCRITURAS del Maestro
                    case (wbs_adr_i[7:0])
                        8'h00: reg_m_in  <= wbs_dat_i; // Guardar m_in
                        8'h04: reg_q_in  <= wbs_dat_i; // Guardar q_in
                        8'h08: mac_start <= wbs_dat_i[0]; // Lanzar pulso Start si manda un 1
                    endcase
                end else begin
                    // LECTURAS del Maestro
                    case (wbs_adr_i[7:0])
                        8'h00: wbs_dat_o <= reg_m_in;
                        8'h04: wbs_dat_o <= reg_q_in;
                        8'h0C: wbs_dat_o <= {31'b0, status_ready}; // Rellenar con ceros, dejar status en el LSB
                        8'h10: wbs_dat_o <= mac_product[31:0];  // Parte baja del acumulador
                        8'h14: wbs_dat_o <= mac_product[63:32]; // Parte alta del acumulador
                        // acumulador tiene más de 64 bits (72 bits)
                        8'h18: wbs_dat_o <= { {(32-(`MAC_ACC_WIDTH-63)){1'b0}}, mac_product[`MAC_ACC_WIDTH:64] }; 
                        default: wbs_dat_o <= '0;
                    endcase
                end
            end
        end
    end

    assign wbs_err_o = 1'b0; // Sin error?

endmodule