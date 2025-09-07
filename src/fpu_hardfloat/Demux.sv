module Demux #( parameter DATA_WIDTH = 16) (
    input [DATA_WIDTH:0] op1,
    input [DATA_WIDTH:0] op2,
    input [1:0] control_signal,
    output logic [DATA_WIDTH:0] ADD1,
    output logic [DATA_WIDTH:0] ADD2,
    output logic [DATA_WIDTH:0] MUL1,
    output logic [DATA_WIDTH:0] MUL2,
    output logic [DATA_WIDTH:0] DIV1,
    output logic [DATA_WIDTH:0] DIV2
);

always_comb begin
    case (control_signal)
        2'b00: begin // addsub
            ADD1 = op1;
            ADD2 = op2; // Desactivar otros operandos
            MUL1 = 0;
            MUL2 = 0;
            DIV1 = 0;
            DIV2 = 0;
        end
        2'b01: begin // mul
            ADD1 = 0;
            ADD2 = 0; // Desactivar otros operandos
            MUL1 = op1;
            MUL2 = op2;
            DIV1 = 0;
            DIV2 = 0;
        end
        2'b10: begin // divsqrt
            ADD1 = 0;
            ADD2 = 0; 
            MUL1 = 0;
            MUL2 = 0;
            DIV1 = op1;
            DIV2 = op2;
        end
        default: begin // Control signal no válida
            ADD1 = 0;
            ADD2 = 0; 
            MUL1 = 0;
            MUL2 = 0;
            DIV1 = 0;
            DIV2 = 0;
        end
    endcase
   end
endmodule
