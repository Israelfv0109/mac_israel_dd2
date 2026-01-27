/*******************************************************************************
 * NIVEL 2: MÓDULOS FUNCIONALES
 * Este archivo agrupa la lógica secuencial del multiplicador y la gestión
 * de la memoria del acumulador.
 ******************************************************************************/

// 1. MULTIPLICADOR DE BOOTH (Instancia FSM + Datapath del nivel 3)
module booth_multiplier #(parameter DATA_WIDTH = 16) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [DATA_WIDTH-1:0] m_in, // Multiplicando
    input  logic [DATA_WIDTH-1:0] q_in, // Multiplicador
    output logic [2*DATA_WIDTH-1:0] result,
    output logic ready
);
    // Cables internos para conectar el cerebro con los músculos (Nivel 3)
    logic load, shift, op_sel;

    // Instancia del Cerebro (FSM)
    booth_fsm #(.DATA_WIDTH(DATA_WIDTH)) control_unit (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .load   (load),
        .shift  (shift),
        .op_sel (op_sel),
        .ready  (ready)
    );

    // Instancia de(Datapath)
    booth_datapath #(.DATA_WIDTH(DATA_WIDTH)) arithmetic_unit (
        .clk     (clk),
        .rst_n   (rst_n),
        .m_in    (m_in),
        .q_in    (q_in),
        .load    (load),
        .shift   (shift),
        .op_sel  (op_sel),
        .product (result)
    );

endmodule

// 2. UNIDAD DE ACUMULACIÓN (Instancia Adder del Nivel 3 + Registro de Guarda)
module accumulator_unit (
    input  logic clk,
    input  logic rst_n,
    input  logic clr_acc,    // Limpia el acumulador a cero
    input  logic acc_en,     // Habilita la suma (se conecta al ready del multiplicador)
    input  logic [31:0] product_in,
    output logic [39:0] acc_out
);
    // Señales internas para el bucle de acumulación
    logic [39:0] current_sum;
    logic [39:0] acc_reg;

    // --- ZOOM: EXTENSIÓN DE SIGNO ---
    // Pasamos el producto de 32 bits a 40 bits para evitar el Overflow
    logic [39:0] product_ext;
    assign product_ext = { {8{product_in[31]}}, product_in };

    // Instancia del Sumador Atómico (Nivel 3)
    adder_40bit mac_adder (
        .a   (product_ext),
        .b   (acc_reg),
        .sum (current_sum)
    );

    // Registro Acumulador: Guarda el resultado solo cuando se le ordena
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_reg <= 40'b0;
        end else if (clr_acc) begin
            acc_reg <= 40'b0;
        end else if (acc_en) begin
            acc_reg <= current_sum;
        end
    end

    // Salida final del acumulador
    assign acc_out = acc_reg;

endmodule