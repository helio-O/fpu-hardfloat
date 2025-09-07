`timescale 1ns/1ps

module tb_fpu_vfloat_fp32;


  logic clk;
  logic reset;

 
  logic [2:0]  operator;
  logic [2:0]  rounding_mode;
  logic        in_valid;
  logic        cpu_ready;
  logic [3:0]  tag;
  logic [31:0] inOp1, inOp2;

  logic        fpu_ready;
  logic        result_valid;
  logic [3:0]  tag_out;
  logic [31:0] result;
  logic        exception;

 
  FPU_VFloat_Wrapper #(
    .EXP_WIDTH(8),
    .MAN_WIDTH(23)
  ) dut (
    .clk(clk),
    .reset(reset),
    .operator(operator),
    .rounding_mode(rounding_mode),
    .in_valid(in_valid),
    .cpu_ready(cpu_ready),
    .tag(tag),
    .inOp1(inOp1),
    .inOp2(inOp2),
    .fpu_ready(fpu_ready),
    .result_valid(result_valid),
    .tag_out(tag_out),
    .result(result),
    .exception(exception)
  );


  initial clk = 0;
  always #5 clk = ~clk;

 
task automatic do_op(input [2:0] op, input [31:0] a, input [31:0] b, input [3:0] t);
  // espera a IDLE 
  wait (fpu_ready == 1);
  @(posedge clk); // alinear handshake

  operator      = op;
  rounding_mode = 3'b000; // RNE
  inOp1         = a;
  inOp2         = b;
  tag           = t;

  in_valid      = 1;
  cpu_ready     = 1;
  @(posedge clk);          // mantener 1 ciclo completo
  in_valid      = 0;
  cpu_ready     = 0;

  // espera al pulso de resultado
  @(posedge result_valid);

  $display("[%0t] OP=%0d tag=%0h : result=0x%08h exception=%b",
            $time, op, tag_out, result, exception);

  // separa operaciones un poco (opcional)
  @(posedge clk);
endtask

 
  initial begin
    // Inicializa entradas
    operator      = 0;
    rounding_mode = 0;
    in_valid      = 0;
    cpu_ready     = 0;
    tag           = 0;
    inOp1         = 0;
    inOp2         = 0;

   
    reset = 1;
    repeat(5) @(posedge clk);
    reset = 0;

    
    // 1.0 + 2.0 = 3.0
    do_op(3'd0, 32'h3f800000, 32'h40000000, 4'h1); // ADD

    // 5.5 - 2.5 = 3.0
    do_op(3'd1, 32'h40b00000, 32'h40200000, 4'h2); // SUB

    // 3.0 * 4.0 = 12.0
    do_op(3'd2, 32'h40400000, 32'h40000000, 4'h3); // MUL

    // 8.0 / 2.0 = 4.0
    do_op(3'd3, 32'h41000000, 32'h40000000, 4'h4); // DIV

    // sqrt(16.0) = 4.0
    do_op(3'd4, 32'h41C80000, 32'h0, 4'h5);        // SQRT
    
    do_op(3'd3, 32'h40000000, 32'h0, 4'hD); // 0 * inf -> NaN, exception=1
    
    $display(">>> Todas las pruebas aplicadas <<<");
    #50 $finish;
  end

endmodule
