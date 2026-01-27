/*******************************************************************************
 * NIVEL 1: TOP LEVEL - UNIDAD MAC COMPLETA
 * Este módulo integra el Multiplicador de Booth y la Unidad de Acumulación.
 ******************************************************************************/

module mac_top #(
    parameter DATA_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,
    
    // --- Puertos de Control ---
    input logic start,      // Inicia una multiplicación individual
    input logic clr_acc,    // Limpia el acumulador a cero (Reset del total)
    
    // --- Puertos de Datos ---
    input logic [DATA_WIDTH-1:0] A_in, // Multiplicando
    input logic [DATA_WIDTH-1:0] B_in, // Multiplicador
    
    // --- Salidas ---
    output logic [39:0] Accumulator,    // Resultado acumulado total
    output logic ready_mac              // Indica que la operación actual terminó
);

    // --- CABLES INTERNOS (Conexiones entre niveles 2) ---
    logic [2*DATA_WIDTH-1:0] internal_product;
    logic mult_done;

    // 1. INSTANCIA DEL MULTIPLICADOR DE BOOTH (Nivel 2)
    // Se encarga de la aritmética secuencial Radix-2
    booth_multiplier #(.DATA_WIDTH(DATA_WIDTH)) multiplicador_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .m_in   (A_in),
        .q_in   (B_in),
        .result (internal_product),
        .ready  (mult_done) // Esta señal avisa cuando el producto es válido
    );

    // 2. INSTANCIA DE LA UNIDAD DE ACUMULACIÓN (Nivel 2)
    // Suma el producto actual al registro de 40 bits
    accumulator_unit acumulador_inst (
        .clk         (clk),
        .rst_n       (rst_n),
        .clr_acc     (clr_acc),
        .acc_en      (mult_done),      // Se activa en el momento que Booth termina
        .product_in  (internal_product),
        .acc_out     (Accumulator)
    );

    // La bandera de salida se sincroniza con el fin de la multiplicación
    assign ready_mac = mult_done;

endmodule