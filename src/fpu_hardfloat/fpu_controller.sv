module FPU_Controller #(
    parameter MAN_WIDTH = 24,
    parameter EXP_WIDTH = 8
)(
    input  logic clk,
    input  logic rst,

    // Handshake entrada
    input  logic in_valid,
    input  logic cpu_ready,

    // Handshake DIV/SQRT
    input  logic div_out_valid,
    input  logic div_in_ready,
    output logic div_in_valid,

    // Parametros y tag
    input  logic [2:0] rounding_mode,
    input  logic [2:0] operator,
    input  logic [3:0] tag_i,

    // Control hacia datapath
    output logic subOp,
    output logic sqrOp,
    output logic fpu_ready,
    output logic res_valid,
    output logic [1:0] op_select_o,
    output logic [3:0] tag_o,
    output logic [2:0] rounding_mode_o,  
    output logic reg_we
);

    typedef enum logic [2:0] {
        S_INIT     = 3'd0,
        S_IDLE     = 3'd1,
        S_START_CMB= 3'd2,
        S_START_DIV = 3'd3,
        S_WAIT_DIV  = 3'd4,
        S_DONE     = 3'd5
    } state_t;

    state_t state, next_state;

    
    logic [2:0] op_q, rnd_q;
    logic [3:0] tag_q;

   
    logic accept_input;
    always_comb begin
        logic is_div_or_sqrt = (operator == 3'd3) || (operator == 3'd4);
        accept_input = (state == S_IDLE) &&
                       in_valid && cpu_ready &&
                       (!is_div_or_sqrt || div_in_ready);
    end

   
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_INIT;
            op_q  <= '0;
            rnd_q <= '0;
            tag_q <= '0;
        end else begin
            state <= next_state;
            if (accept_input) begin
                op_q  <= operator;
                rnd_q <= rounding_mode;
                tag_q <= tag_i;
            end
        end
    end

   
    assign tag_o            = tag_q;
    assign rounding_mode_o  = rnd_q;

    // Deco
    logic [2:0] op_eff;
    always_comb begin
        op_eff = (state == S_IDLE) ? operator : op_q;
    end

    // subOp / sqrOp
    always_comb begin
        subOp = (op_eff == 3'd1); // SUB
        sqrOp = (op_eff == 3'd4); // SQRT (DIV si 0)
    end

    // demux_control_o 
    always_comb begin
        unique case (op_eff)
            3'd0, 3'd1: op_select_o = 2'b00; // ADD/SUB
            3'd2:       op_select_o = 2'b01; // MUL
            3'd3,3'd4:  op_select_o = 2'b10; // DIV/SQRT
            default:    op_select_o = 2'b00;
        endcase
    end

    // FSM
    always_comb begin
        // defaults
        next_state   = state;
        fpu_ready    = 1'b0;
        res_valid    = 1'b0;
        div_in_valid = 1'b0;
        reg_we       = 1'b0;

        unique case (state)
            S_INIT: begin
                next_state = S_IDLE;
            end

            S_IDLE: begin
                fpu_ready = 1'b1;
                if (in_valid && cpu_ready) begin
                    unique case (operator)
                        3'd0, 3'd1, 3'd2: next_state = S_START_CMB;     // ADD/SUB/MUL
                        3'd3, 3'd4:       next_state = div_in_ready ? S_START_DIV : S_IDLE; // DIV/SQRT
                        default:          next_state = S_IDLE;
                    endcase
                end
            end

            S_START_CMB: begin
                reg_we     = 1'b1;   // captura resultado combinacional
                next_state = S_DONE;
            end

            S_START_DIV: begin
                div_in_valid = 1'b1; // lanza op secuencial
                next_state   = S_WAIT_DIV;
            end

            S_WAIT_DIV: begin
                if (div_out_valid) begin
                    reg_we     = 1'b1; 
                    next_state = S_DONE;
                end
            end

            S_DONE: begin
                res_valid  = 1'b1;  // publica 1 ciclo
                next_state = S_IDLE;
            end

            default: next_state = S_INIT;
        endcase
    end

endmodule
