`timescale 1ns/1ps

module booth_datapath #(parameter DATA_WIDTH = 16) (
    input  logic clk, rst_n,
    input  logic [DATA_WIDTH-1:0] m_in, q_in,
    input  logic load, shift, op_sel,
    output logic [2*DATA_WIDTH-1:0] product
);
    logic signed [DATA_WIDTH-1:0] A, M;
    logic [DATA_WIDTH-1:0] Q;
    logic q_prev;

    // --- 1. ALU DE 18 BITS (Para evitar el desbordamiento del signo) ---
    logic signed [DATA_WIDTH+1:0] ext_A;
    logic signed [DATA_WIDTH+1:0] ext_M;
    logic signed [DATA_WIDTH+1:0] alu_out;
    
    // Extendemos el signo copiando el bit más significativo (MSB) DOS VECES
    assign ext_A = {{2{A[DATA_WIDTH-1]}}, A};
    assign ext_M = {{2{M[DATA_WIDTH-1]}}, M};

    // Multiplexor de suma/resta (Pura combinacional)
    always_comb begin
        case ({Q[1], Q[0], q_prev})
            3'b001, 3'b010: alu_out = ext_A + ext_M;
            3'b101, 3'b110: alu_out = ext_A - ext_M;
            3'b011:         alu_out = ext_A + (ext_M <<< 1); // ¡Ahora el 2M sí cabe!
            3'b100:         alu_out = ext_A - (ext_M <<< 1);
            default:        alu_out = ext_A;                 // +0
        endcase
    end

    // --- 2. CABLE DE RECORRIDO (SHIFT) DE 34 BITS ---
    // Unimos los 18 bits de la ALU, los 16 de Q y 1 de q_prev = 35 bits
    logic signed [2*DATA_WIDTH+2:0] shift_reg;
    assign shift_reg = {alu_out, Q, q_prev};

    // --- 3. REGISTROS SECUENCIALES ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {A, Q, q_prev} <= '0;
            M <= '0;
        end else if (load) begin
            A <= '0;
            M <= m_in;
            Q <= q_in;
            q_prev <= 1'b0;
        end else if (op_sel && shift) begin
            // Shift aritmético seguro. 
            // Tomamos los 33 bits inferiores [32:0] para guardarlos en {A, Q, q_prev}
            {A, Q, q_prev} <= (shift_reg >>> 2); 
        end
    end

    assign product = {A, Q};

endmodule