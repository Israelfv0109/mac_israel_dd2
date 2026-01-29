/*******************************************************************************
 * NIVEL 3: BLOQUES ATOMICOS DE LA UNIDAD MAC
 * Incluye: FSM de Booth, Datapath de Booth y Sumador de 40 bits
 ******************************************************************************/
`timescale 1ns/1ps

// 1. FSM de Booth
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
            LOAD: begin
                load = 1'b1;
                next_state = CALC;
            end
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

// 2. Datapath de Booth
module booth_datapath #(parameter DATA_WIDTH = 16) (
    input  logic clk, rst_n,
    input  logic [DATA_WIDTH-1:0] m_in, q_in,
    input  logic load, shift, op_sel,
    output logic [2*DATA_WIDTH-1:0] product
);
    logic signed [DATA_WIDTH-1:0] A, M;
    logic [DATA_WIDTH-1:0] Q;
    logic q_prev;

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
            // Cálculo y Desplazamiento en un solo paso seguro
            case ({Q[0], q_prev})
                2'b01:   {A, Q, q_prev} <= $signed({A + M, Q, q_prev}) >>> 1;
                2'b10:   {A, Q, q_prev} <= $signed({A - M, Q, q_prev}) >>> 1;
                default: {A, Q, q_prev} <= $signed({A, Q, q_prev}) >>> 1;
            endcase
        end
    end

    assign product = {A, Q};
endmodule

// 3. Sumador de 40 bits
module adder_40bit (
    input  logic signed [39:0] a,
    input  logic signed [39:0] b,
    output logic signed [39:0] sum
);
    assign sum = a + b;
endmodule