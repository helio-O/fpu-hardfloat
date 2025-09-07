module FPU_Wrapper #(
    parameter MAN_WIDTH = 53,   // sigWidth (incluye bit implícito)
    parameter EXP_WIDTH = 11     // expWidth
)(
    // Entradas (IEEE en inOp1/2)
    input  [3:0]                               tag,
    input  [MAN_WIDTH + EXP_WIDTH - 1:0]       inOp1,
    input  [MAN_WIDTH + EXP_WIDTH - 1:0]       inOp2,
    input                                      clk,
    input  [2:0]                               operator,
    input                                      cpu_ready,
    input  [2:0]                               rounding_mode,
    input                                      reset,       // activo alto
    input                                      in_valid,

    // Salidas
    output [3:0]                               tag_out,
    output                                     result_valid,
    output                                     fpu_ready,
    output [4:0]                               exceptionFlags,
    output [MAN_WIDTH + EXP_WIDTH - 1:0]       result
);

    // Anchos
    localparam IEEE_WIDTH = MAN_WIDTH + EXP_WIDTH;
    localparam REC_WIDTH  = MAN_WIDTH + EXP_WIDTH + 1;

    // Control HardFloat
    logic control = 1'b1; // tininess after rounding

    // Señales desde la FSM
    logic        subOp, sqrOp;
    logic [1:0]  op_select;
    logic        we_control;
    logic        ds_in_valid;
    logic [2:0]  rounding_mode_latched; 
    logic [3:0]  tag_o_int;

    // Handshake div/sqrt
    logic in_ready_out;
    logic out_valid;

    // Buses recFN
    logic [REC_WIDTH-1:0] outDecoOP1, outDecoOP2;
    logic [REC_WIDTH-1:0] addOp1, addOp2, mulOp1, mulOp2, divOp1, divOp2;
    logic [REC_WIDTH-1:0] addOut, mulOut, divOut, outMux;

    // Flags
    logic [4:0] add_flags, mul_flags, div_flags, ex_flags_sel;

    // Registros de salida
    logic [REC_WIDTH-1:0] result_reg;
    logic [4:0]       flags_reg;
    logic [3:0]       tag_reg;

    // ---------------- FSM / Controller ----------------
    FPU_Controller #(.MAN_WIDTH(MAN_WIDTH), .EXP_WIDTH(EXP_WIDTH)) controller (
        .clk(clk),
        .rst(reset),
        .in_valid(in_valid),
        .cpu_ready(cpu_ready),

        .div_out_valid(out_valid),
        .div_in_ready(in_ready_out),
        .div_in_valid(ds_in_valid),

        .rounding_mode(rounding_mode),
        .operator(operator),
        .tag_i(tag),

        .subOp(subOp),
        .sqrOp(sqrOp),
        .fpu_ready(fpu_ready),
        .res_valid(result_valid),
        .op_select_o(op_select),
        .tag_o(tag_o_int),
        .rounding_mode_o(rounding_mode_latched),
        .reg_we(we_control)
    );

    // ---------------- Decoder IEEE -> recFN ----------------
    fNToRecFN #(EXP_WIDTH, MAN_WIDTH) dec1 (.in(inOp1), .out(outDecoOP1));
    fNToRecFN #(EXP_WIDTH, MAN_WIDTH) dec2 (.in(inOp2), .out(outDecoOP2));

    // ---------------- Demux operandos (recFN) ----------------
    Demux #(REC_WIDTH) demux (
        .op1(outDecoOP1), .op2(outDecoOP2), .control_signal(op_select),
        .ADD1(addOp1), .ADD2(addOp2),
        .MUL1(mulOp1), .MUL2(mulOp2),
        .DIV1(divOp1), .DIV2(divOp2)
    );

    // ---------------- Unidades aritméticas (recFN) ----------------
    addRecFN #(EXP_WIDTH, MAN_WIDTH) u_add (
        .control(control),
        .subOp(subOp),
        .a(addOp1), .b(addOp2),
        .roundingMode(rounding_mode_latched), 
        .out(addOut),
        .exceptionFlags(add_flags)
    );

    mulRecFN #(EXP_WIDTH, MAN_WIDTH) u_mul (
        .control(control),
        .a(mulOp1), .b(mulOp2),
        .roundingMode(rounding_mode_latched),
        .out(mulOut),
        .exceptionFlags(mul_flags)
    );

    divSqrtRecFN_small #(EXP_WIDTH, MAN_WIDTH) u_divsqrt (
        .nReset(~reset),                    // activo bajo
        .clock(clk),
        .control(control),
        .inReady(in_ready_out),
        .inValid(ds_in_valid),
        .sqrtOp(sqrOp),
        .a(divOp1), .b(divOp2),
        .roundingMode(rounding_mode_latched),
        .outValid(out_valid),
        .sqrtOpOut(/*unused*/),
        .out(divOut),
        .exceptionFlags(div_flags)
    );

    // ---------------- Selección resultado/flags (recFN) ----------------
    always_comb begin
        unique case (op_select)
            2'b00: ex_flags_sel = add_flags;
            2'b01: ex_flags_sel = mul_flags;
            2'b10: ex_flags_sel = div_flags;
            default: ex_flags_sel = '0;
        endcase
    end

    Mux3to1 #(REC_WIDTH) mux_res (
        .input1(addOut), .input2(mulOut), .input3(divOut),
        .control_signal(op_select),
        .out(outMux)
    );

    // ---------------- Registro de salida (recFN + flags + tag) ----------------
    we_register #(.SIZE(REC_WIDTH)) res_reg (
        .clk(clk), .rst(reset),
        .data_in(outMux),
        .we(we_control),
        .data_out(result_reg)
    );

    we_register #(.SIZE(5)) flags_reg_i (
        .clk(clk), .rst(reset),
        .data_in(ex_flags_sel),
        .we(we_control),
        .data_out(flags_reg)
    );

    we_register #(.SIZE(4)) tag_reg_i (
        .clk(clk), .rst(reset),
        .data_in(tag_o_int),
        .we(we_control),
        .data_out(tag_reg)
    );

    assign exceptionFlags = flags_reg;   // flags registrados con el resultado
    assign tag_out        = tag_reg;     // tag alineado a result
    
    // ---------------- Encoder recFN -> IEEE ----------------
    recFNToFN #(EXP_WIDTH, MAN_WIDTH) enc (
        .in(result_reg),
        .out(result)
    );

endmodule
