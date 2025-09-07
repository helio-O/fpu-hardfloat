module Mux3to1 # (parameter DATA_WIDTH = 32) (
    input [DATA_WIDTH:0] input1,
    input [DATA_WIDTH:0] input2,
    input [DATA_WIDTH:0] input3,
    input [1:0] control_signal,
    output reg [DATA_WIDTH:0] out
);

// Lógica del mux
always_comb begin
    case (control_signal)
        2'b00: out = input1; // Control signal indica selección de input1
        2'b01: out = input2; // Control signal indica selección de input2
        2'b10: out = input3; // Control signal indica selección de input3
        default: out = '0; // Valor por defecto si la señal de control no es válida
    endcase
end

endmodule
