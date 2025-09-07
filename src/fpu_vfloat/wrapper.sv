// FPU_VFloat_Wrapper.sv
// Instancia el controller y los M�DULOS VHDL de VFloat directamente (sin adapters).
// IMPORTANTE: Compila este wrapper con el mismo ancho IEEE que las entidades VHDL enlazadas.
//   - Ej: si usas las variantes FP32 de VFloat ? IEEE_W=32 (EXP_WIDTH=8, MAN_WIDTH=23)
//   - Si el DIV es FP64 en tus fuentes, genera un wrapper FP64 para DIV (o separa wrappers por formato).

module FPU_VFloat_Wrapper #(
  parameter int EXP_WIDTH = 5,
  parameter int MAN_WIDTH = 10,
  localparam int IEEE_W   = 1 + EXP_WIDTH + MAN_WIDTH,

  // op 
  parameter logic [2:0] OP_ADD  = 3'd0,
  parameter logic [2:0] OP_SUB  = 3'd1,
  parameter logic [2:0] OP_MUL  = 3'd2,
  parameter logic [2:0] OP_DIV  = 3'd3,
  parameter logic [2:0] OP_SQRT = 3'd4
)(
  input  logic                clk,
  input  logic                reset,

 
  input  logic [2:0]          operator,
  input  logic [2:0]          rounding_mode,
  input  logic                in_valid,
  input  logic                cpu_ready,
  input  logic [3:0]          tag,
  input  logic [IEEE_W-1:0]   inOp1,
  input  logic [IEEE_W-1:0]   inOp2,

  output logic                fpu_ready,
  output logic                result_valid,
  output logic [3:0]          tag_out,
  output logic [IEEE_W-1:0]   result,
  output logic                exception
);

  // señales controller
  logic                start_add, start_mul, start_div, start_sqrt;
  logic                ready_pulse, vfloat_round;
  logic [IEEE_W-1:0]   a_lat, b_lat;

  logic                done_add,  done_mul,  done_div,  done_sqrt;
  logic [IEEE_W-1:0]   y_add,     y_mul,     y_div,     y_sqrt;
  logic                exc_add,   exc_mul,   exc_div,   exc_sqrt;

  logic                is_sub_o; 

  
  FPU_VFloat_Controller #(
    .EXP_WIDTH(EXP_WIDTH),
    .MAN_WIDTH(MAN_WIDTH),
    .OP_ADD   (OP_ADD),
    .OP_SUB   (OP_SUB),
    .OP_MUL   (OP_MUL),
    .OP_DIV   (OP_DIV),
    .OP_SQRT  (OP_SQRT)
  ) u_ctrl (
    .clk(clk), .reset(reset),
    .operator(operator), .rounding_mode(rounding_mode),
    .in_valid(in_valid), .cpu_ready(cpu_ready),
    .tag(tag), .inOp1(inOp1), .inOp2(inOp2),

    .fpu_ready(fpu_ready), .result_valid(result_valid),
    .tag_out(tag_out), .result(result), .exception(exception),

    // señales comunes
    .start_add(start_add), .start_mul(start_mul),
    .start_div(start_div), .start_sqrt(start_sqrt),
    .ready_pulse(ready_pulse), .vfloat_round(vfloat_round),
    .a_latched(a_lat), .b_latched(b_lat),

   
    .done_add(done_add), .done_mul(done_mul),
    .done_div(done_div), .done_sqrt(done_sqrt),
    .y_add(y_add), .y_mul(y_mul), .y_div(y_div), .y_sqrt(y_sqrt),
    .exc_add(exc_add), .exc_mul(exc_mul), .exc_div(exc_div), .exc_sqrt(exc_sqrt)
  );

 
  assign is_sub_o = u_ctrl.is_sub_o;


  localparam logic VFLOAT_STALL  = 1'b0; // sin backpressure interno
  localparam logic VFLOAT_EXC_IN = 1'b0; // sin encadenar excepciones

  // sub invertir signo
  wire [IEEE_W-1:0] b_eff = is_sub_o ? {~b_lat[IEEE_W-1], b_lat[IEEE_W-2:0]} : b_lat;

 
  fp_adder u_add (
    .CLK           (clk),
    .RESET         (reset),
    .STALL         (VFLOAT_STALL),
    .OP1           (a_lat),
    .OP2           (b_eff),
    .READY         (ready_pulse & start_add),
    .ROUND         (vfloat_round),
    .EXCEPTION_IN  (VFLOAT_EXC_IN),
    .DONE          (done_add),
    .RESULT        (y_add),
    .EXCEPTION_OUT (exc_add)
  );

  
  variable_precision_multiplier u_mul (
    .CLK           (clk),
    .RESET         (reset),
    .STALL         (VFLOAT_STALL),
    .OP1           (a_lat),
    .OP2           (b_lat),
    .READY         (ready_pulse & start_mul),
    .ROUND         (vfloat_round),
    .EXCEPTION_IN  (VFLOAT_EXC_IN),
    .DONE          (done_mul),
    .RESULT        (y_mul),
    .EXCEPTION_OUT (exc_mul)
  );

 
  variable_precision_divider u_div (
    .CLK           (clk),
    .RESET         (reset),
    .STALL         (VFLOAT_STALL),
    .OP1           (a_lat),
    .OP2           (b_lat),
    .READY         (ready_pulse & start_div),
    .ROUND         (vfloat_round),
    .EXCEPTION_IN  (VFLOAT_EXC_IN),
    .DONE          (done_div),
    .RESULT        (y_div),
    .EXCEPTION_OUT (exc_div)
  );

 
  variable_precision_squareroot u_sqrt (
    .CLK           (clk),
    .RESET         (reset),
    .STALL         (VFLOAT_STALL),
    .OP            (a_lat),
    .READY         (ready_pulse & start_sqrt),
    .ROUND         (vfloat_round),
    .EXCEPTION_IN  (VFLOAT_EXC_IN),
    .DONE          (done_sqrt),
    .RESULT        (y_sqrt),
    .EXCEPTION_OUT (exc_sqrt)
  );

endmodule
