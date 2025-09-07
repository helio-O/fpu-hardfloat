typedef enum {
 INIT,
 READY,
 MUL,
 ADD,
 DIV,
 DONE
} State;

State current_state,next_state;

module FPU_Controller #(parameter MAN_WIDTH = 23, parameter EXP_WIDTH = 8  )(
    input logic clk,        
    input logic rst,  
    input logic in_valid,
    input logic cpu_ready,
    input logic div_out_valid, //divsqrt 
    input logic div_in_ready, //divsqrt
    input logic [2:0]rounding_mode,
    input logic [2:0] operator,
    input logic [3:0] tag_i,
        
    
    output logic subOp,
    output logic sqrOp,
    output logic fpu_ready,
    output logic res_valid, //revisar
    output logic [1:0] demux_control_o,
    output logic [3:0] tag_o,
    output logic reg_we
   
);

// Definición de parámetros para los estados


// Definición de registros de estado
logic [2:0] next_state;
logic [2:0] current_state;
logic [1:0] demux_control;

// Asignación del estado inicial
always_ff @(posedge clk or negedge rst) begin
    if(~rst) begin
        current_state <= INIT;
        fpu_ready <= 1'b1;
        res_valid <= 1'b0;
        reg_we <= 1'b0;
    end
    else begin
        current_state <= next_state;
        tag_o <= tag_i;
    end
end

// Lógica de la máquina de estados
always_comb begin
    case (current_state)
        INIT: begin
            if(cpu_ready && fpu_ready) begin
                next_state = READY;
            end else begin
                next_state = INIT;
            end
            
        end
        READY: begin
            reg_we <= 1'b1;
            if(in_valid) begin
                  case (operator)
                        3'b000, 3'b001: begin // suma o resta
                        next_state = ADD;
                        demux_control_o = 2'b00;
                        subOp = (operator == 3'b001) ? 1'b1 : 1'b0; // Si es resta, subOp es 1
                    end
                    3'b010: begin // multiplicación
                        next_state = MUL;
                        demux_control_o = 2'b01;
                    end
                    3'b011, 3'b100: begin // división o raíz cuadrada
                    demux_control_o = 2'b10;
                        if (div_in_ready == 1) begin
                            next_state = DIV;
                            sqrOp = (operator == 3'b100) ? 1'b1 : 1'b0; // Si es sqrt, sqrOp es 1
                        end
                    end
                        default: next_state = INIT /* estado por defecto */;
                    endcase
                
           end
           else begin
                next_state = READY; // Permanecer en READY mientras in_valid sea 0
            end
     
        end
        MUL, ADD: begin
            fpu_ready = 1'b0;
            res_valid = 1'b1;
            next_state = DONE;
        end
        DIV: begin//TODO
            fpu_ready = 1'b0;
            if(div_out_valid) begin 
                res_valid = 1'b1;
                next_state = DONE;
            end else begin
            next_state = DIV;
            end   
        end
        DONE: begin
            fpu_ready = 1'b1; // Listo para recibir otra instrucción
            res_valid = 1'b0; // Resetear res_valid para la próxima operación
            next_state = INIT;
        end
        default: begin
            // Manejo de casos no previstos
            next_state = INIT;
            subOp = 1'b0; // Reiniciar todas las salidas en caso de estado no previsto
            sqrOp = 1'b0;
            fpu_ready = 1'b1;
            res_valid = 1'b0;
        end
    endcase
end

endmodule
