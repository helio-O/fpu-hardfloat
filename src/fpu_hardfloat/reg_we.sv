module we_register #( parameter SIZE = 32)(
    input logic rst,
    input logic clk,
    input logic [SIZE:0]data_in,
    input logic we,
    output logic [SIZE:0] data_out
);

always_ff @(posedge clk) begin
 if (!rst) begin
            data_out <= 0; // Reiniciar el registro a cero
        end else if (we) begin
            data_out <= data_in; // Cargar datos de entrada si la señal de escritura está activa
        end
end

endmodule
