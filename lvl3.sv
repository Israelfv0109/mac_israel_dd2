/*******************************************************************************
 * NIVEL 3: BLOQUES ATÓMICOS DE LA UNIDAD MAC
 * Incluye: FSM de Booth, Datapath de Booth y Sumador de 40 bits
 ******************************************************************************/

// 1. Maquina de estados para controlar el proceso de Booth
module booth_fsm #(parameter DATA_WIDTH = 16) (
    input  logic clk, rst_n, start,
    output logic load, shift, op_sel, ready
);
    typedef enum logic [1:0] {IDLE, LOAD, CALC, DONE} state_t;
    state_t state, next_state;
    logic [$clog2(DATA_WIDTH):0] bit_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            bit_cnt <= '0;
        end else begin
            state <= next_state;
            if (state == CALC) bit_cnt <= bit_cnt + 1'b1;
            else if (state == IDLE) bit_cnt <= '0;
        end
    end

    always_comb begin
        {load, shift, op_sel, ready} = '0;
        case (state)
            IDLE: next_state = start ? LOAD : IDLE;
            LOAD: next_state = CALC;
            CALC: begin
                op_sel = 1'b1;
                shift  = 1'b1;
                next_state = (bit_cnt == DATA_WIDTH-1) ? DONE : CALC;
            end
            DONE: begin
                ready = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

// 2. Registros y ALU para la aritmética de Booth
module booth_datapath #(parameter DATA_WIDTH = 16) (
    input  logic clk, rst_n,
    input  logic [DATA_WIDTH-1:0] m_in, q_in,
    input  logic load, shift, op_sel,
    output logic [2*DATA_WIDTH-1:0] product
);
    logic signed [DATA_WIDTH:0] A, M;
    logic [DATA_WIDTH-1:0] Q;
    logic q_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {A, Q, q_prev} <= '0;
            M <= '0;
        end else if (load) begin
            A <= '0;
            M <= {m_in[DATA_WIDTH-1], m_in}; // Extensión de signo
            Q <= q_in;
            q_prev <= 1'b0;
        end else if (shift) begin
            // Desplazamiento aritmético para preservar el signo
            {A, Q, q_prev} <= $signed({A, Q, q_prev}) >>> 1;
        end else if (op_sel) begin
            case ({Q[0], q_prev})
                2'b01: A <= A + M;
                2'b10: A <= A - M;
                default: A <= A;
            endcase
        end
    end
    assign product = {A[DATA_WIDTH-1:0], Q};
endmodule

// 3. SUMADOR DE MAC: Sumador de 40 bits para el acumulador final
module adder_40bit (
    input  logic signed [39:0] a,
    input  logic signed [39:0] b,
    output logic signed [39:0] sum
);
    assign sum = a + b;
endmodule