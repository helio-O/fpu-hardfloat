// Registro write-enable 
module we_register #(
    parameter SIZE = 32
)(
    input  logic             clk,
    input  logic             rst,           // reset activo alto, síncrono
    input  logic [SIZE-1:0]  data_in,
    input  logic             we,
    output logic [SIZE-1:0]  data_out
);
    always_ff @(posedge clk) begin
        if (rst)       data_out <= '0;
        else if (we)   data_out <= data_in;
    end
endmodule