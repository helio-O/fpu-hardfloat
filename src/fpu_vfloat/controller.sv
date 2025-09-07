module FPU_VFloat_Controller #(
  parameter int EXP_WIDTH = 8,
  parameter int MAN_WIDTH = 23,
  localparam int IEEE_W   = 1 + EXP_WIDTH + MAN_WIDTH,


  parameter logic [2:0] OP_ADD  = 3'd0,
  parameter logic [2:0] OP_SUB  = 3'd1,
  parameter logic [2:0] OP_MUL  = 3'd2,
  parameter logic [2:0] OP_DIV  = 3'd3,
  parameter logic [2:0] OP_SQRT = 3'd4
)(
  input  logic                clk,
  input  logic                reset,

  // Interfaz CPU
  input  logic [2:0]          operator,         
  input  logic [2:0]          rounding_mode,    // 000:RNE
  input  logic                in_valid,
  input  logic                cpu_ready,
  input  logic [3:0]          tag,
  input  logic [IEEE_W-1:0]   inOp1,
  input  logic [IEEE_W-1:0]   inOp2,

  output logic                fpu_ready,
  output logic                result_valid,
  output logic [3:0]          tag_out,
  output logic [IEEE_W-1:0]   result,
  output logic                exception,       

 
  output logic                is_sub_o,

  
  output logic                start_add,
  output logic                start_mul,
  output logic                start_div,
  output logic                start_sqrt,
  output logic                ready_pulse,     
  output logic                vfloat_round,     // 1=RNE, 0=trunc
  output logic [IEEE_W-1:0]   a_latched,
  output logic [IEEE_W-1:0]   b_latched,

  
  input  logic                done_add,
  input  logic                done_mul,
  input  logic                done_div,
  input  logic                done_sqrt,
  input  logic [IEEE_W-1:0]   y_add,
  input  logic [IEEE_W-1:0]   y_mul,
  input  logic [IEEE_W-1:0]   y_div,
  input  logic [IEEE_W-1:0]   y_sqrt,
  input  logic                exc_add,
  input  logic                exc_mul,
  input  logic                exc_div,
  input  logic                exc_sqrt
);

  // Estados
  typedef enum logic [2:0] { S_INIT, S_IDLE, S_START, S_BUSY, S_DONE } state_t;
  state_t state, next_state;

  logic [2:0]  op_latched;
  logic [3:0]  tag_latched;

  
  logic op_done;


  function logic map_round(input logic [2:0] rm);
    return (rm == 3'b000); 
  endfunction


  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state        <= S_INIT;
      op_latched   <= '0;
      vfloat_round <= 1'b1; 
      tag_latched  <= '0;
      a_latched    <= '0;
      b_latched    <= '0;
    end else begin
      state <= next_state;
      if (state == S_IDLE && in_valid && cpu_ready) begin
        op_latched   <= operator;
        vfloat_round <= map_round(rounding_mode);
        tag_latched  <= tag;
        a_latched    <= inOp1;
        b_latched    <= inOp2;
      end
    end
  end

  // Flag SUB
  assign is_sub_o = (op_latched == OP_SUB);

  // FSM + control
  always_comb begin
    next_state   = state;
    fpu_ready    = 1'b0;
    result_valid = 1'b0;

    start_add    = 1'b0;
    start_mul    = 1'b0;
    start_div    = 1'b0;
    start_sqrt   = 1'b0;
    ready_pulse  = 1'b0;

    unique case (state)
      S_INIT: next_state = S_IDLE;

      S_IDLE: begin
        fpu_ready = 1'b1;
        if (in_valid && cpu_ready) next_state = S_START;
      end

      S_START: begin
        // Pulso de arranque + READY
        ready_pulse = 1'b1;
        unique case (op_latched)
          OP_ADD, OP_SUB: start_add  = 1'b1;
          OP_MUL:         start_mul  = 1'b1;
          OP_DIV:         start_div  = 1'b1;
          OP_SQRT:        start_sqrt = 1'b1;
          default: ;
        endcase
        next_state = S_BUSY;
      end

      S_BUSY: begin
        if (op_done) next_state = S_DONE;
      end

      S_DONE: begin
        result_valid = 1'b1;  // 1 ciclo
        next_state   = S_IDLE;
      end

      default: next_state = S_IDLE;
    endcase
  end

 
  always_comb begin
    op_done = ( (op_latched==OP_ADD || op_latched==OP_SUB) && done_add  ) ||
              ( (op_latched==OP_MUL)                      && done_mul  ) ||
              ( (op_latched==OP_DIV)                      && done_div  ) ||
              ( (op_latched==OP_SQRT)                     && done_sqrt );
  end

  // Mux de resultado
  always_comb begin
    unique case (op_latched)
      OP_ADD, OP_SUB: begin result = y_add;  exception = exc_add;  end
      OP_MUL:         begin result = y_mul;  exception = exc_mul;  end
      OP_DIV:         begin result = y_div;  exception = exc_div;  end
      OP_SQRT:        begin result = y_sqrt; exception = exc_sqrt; end
      default:        begin result = '0;     exception = 1'b0;     end
    endcase
  end

  assign tag_out = tag_latched;

endmodule
