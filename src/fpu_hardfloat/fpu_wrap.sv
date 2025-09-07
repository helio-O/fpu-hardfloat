module FPU_Wrapper #(
    parameter MAN_WIDTH = 24,   // Tamaño de la mantisa
    parameter EXP_WIDTH = 8     // Tamaño del exponente
)(
    input [3:0] tag,            // Entrada: Etiqueta
    input [MAN_WIDTH + EXP_WIDTH - 1:0] inOp1,  // Entrada: Operando 1
    input [MAN_WIDTH + EXP_WIDTH - 1:0] inOp2,  // Entrada: Operando 2
    input clk,                  // Reloj
    input [2:0] operator,       // Operador
    input cpu_ready,            // CPU lista
    input [2:0] rounding_mode,  // Modo de redondeo
    input reset,                // Reset
    input in_valid,             // Datos de entrada válidos
    
    output [3:0] tag_out,       
    output result_valid,       
    output fpu_ready,           
    output [MAN_WIDTH + EXP_WIDTH - 1:0] result  
);
    logic control = 1'b1;
    logic subOP;
    logic divOP;
    logic [4:0] ex_flags;
    logic [1:0] demux_control;
    logic we_control;
    
    logic [EXP_WIDTH + MAN_WIDTH:0] outDecoOP1;
    logic [EXP_WIDTH + MAN_WIDTH:0] outDecoOP2;
    logic [EXP_WIDTH + MAN_WIDTH:0] outMux;
    logic [EXP_WIDTH + MAN_WIDTH:0] outReg1;
    //logic [EXP_WIDTH + MAN_WIDTH:0] outReg2;
    
    
    logic [EXP_WIDTH + MAN_WIDTH:0] addOp1;
    logic [EXP_WIDTH + MAN_WIDTH:0] addOp2;
    logic [EXP_WIDTH + MAN_WIDTH:0] mulOp1;
    logic [EXP_WIDTH + MAN_WIDTH:0] mulOp2;
    logic [EXP_WIDTH + MAN_WIDTH:0] divOp1;
    logic [EXP_WIDTH + MAN_WIDTH:0] divOp2;

    logic [EXP_WIDTH + MAN_WIDTH:0] addOut;
    logic [EXP_WIDTH + MAN_WIDTH:0] mulOut;
    logic [EXP_WIDTH + MAN_WIDTH:0] divOut;
    
    logic divOpOut; //opcion salida div
    logic in_ready_out;
    logic out_valid;
    
FPU_Controller #(MAN_WIDTH, EXP_WIDTH) controller (
    .clk(clk),
    .rst(reset),
    .in_valid(in_valid),
    .cpu_ready(cpu_ready),
    .div_out_valid(out_valid),
    .div_in_ready(in_ready_out),
    .rounding_mode(rounding_mode),
    .operator(operator),
    .tag_i(tag),
    
    .subOp(subOp),
    .sqrOp(sqrOp),
    .fpu_ready(fpu_ready),
    .res_valid(result_valid),
    .demux_control_o(demux_control),
    .tag_o(tag_out),
    .reg_we(we_control)

    
);


Demux #(MAN_WIDTH + EXP_WIDTH ) demux (
    .op1(outDecoOP1),
    .op2(outDecoOP2),
    .control_signal(demux_control),
    .ADD1(addOp1), //operando 1 de addRecFN
    .ADD2(addOp2), //operando 2
    .MUL1(mulOp1), //operando 1 de Mul  
    .MUL2(mulOp2),
    .DIV1(divOp1),
    .DIV2(divOp2)
);


Mux3to1 #(MAN_WIDTH + EXP_WIDTH ) mux (
    .input1(addOut),
    .input2(mulOut),
    .input3(divOut), //o salida del register
    .control_signal(demux_control),
    .out(outMux)
    
);

addRecFN #(EXP_WIDTH, MAN_WIDTH) addRecFN_inst (
    .control(control),
    .subOp(subOp),
    .a(addOp1),
    .b(addOp2),
    .roundingMode(rounding_mode),
    .out(addOut),
    .exceptionFlags(ex_flags)
);

mulRecFN #(EXP_WIDTH, MAN_WIDTH) mulRecFN_inst (
    .control(control),
    .a(mulOp1),
    .b(mulOp2),
    .roundingMode(rounding_mode),
    .out(mulOut),
    .exceptionFlags(ex_flags)
);

divSqrtRecFN_small #(EXP_WIDTH, MAN_WIDTH) divSqrtRecFN_small_inst (
    .nReset(reset), 
    .clock(clk), 
    .control(control),
    .inReady(in_ready_out), 
    .inValid(in_valid),
    .sqrtOp(sqrOp),
    .a(divOp1),
    .b(divOp2),
    .roundingMode(rounding_mode),
    .outValid(out_valid), 
    .sqrtOpOut(divOpOut), 
    .out(divOut), 
    .exceptionFlags(ex_flags) 
);

fNToRecFN #(EXP_WIDTH,MAN_WIDTH) decoderOp1(
    .in(inOp1),
    .out(outDecoOP1)
);
fNToRecFN #(EXP_WIDTH,MAN_WIDTH) decoderOp2(
    .in(inOp2),
    .out(outDecoOP2)
);

recFNToFN#(EXP_WIDTH,MAN_WIDTH) encoder(
    .in(outMux),
    .out(result)
);

/*
we_register #(EXP_WIDTH + MAN_WIDTH) register(
   .rst(reset),
   .clk(clk),
   .data_in(divOut),
   .we(out_valid),
   .data_out(outReg1)
);*/

endmodule


