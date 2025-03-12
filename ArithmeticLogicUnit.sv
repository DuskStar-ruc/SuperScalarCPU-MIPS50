`timescale 1us/1us

`include "defs.sv"

module ALU(input [31:0] x, input [31:0] y, input [3:0] op, output [31:0] res, output overflow);
    wire [31:0] sra;
    wire overflow;
    assign sra = $signed(y) >>> x[4:0]; //不是，为什么这个放到底下表达式里就会变成逻辑右移啊
    assign overflow = (op == ALU_ADD) ? (x[31] == y[31] && x[31] != res[31]) :
                      (op == ALU_SUB) ? (x[31] != y[31] && x[31] != res[31]) : 0;
    assign res = (op == ALU_ADD) ? x + y :
                 (op == ALU_SUB) ? x - y :
                 (op == ALU_AND) ? x & y :
                 (op == ALU_OR) ? x | y :
                 (op == ALU_XOR) ? x ^ y :
                 (op == ALU_NOR) ? ~(x | y) :
                 (op == ALU_SLL) ? y << x[4:0] :
                 (op == ALU_SRL) ? y >> x[4:0] :
                 (op == ALU_SRA) ? sra :
                 (op == ALU_SLT) ? ($signed(x) < $signed(y)) :
                 (op == ALU_SLTU) ? (x < y) :
                 (op == ALU_X) ? x :
                 (op == ALU_Y) ? y :
                 (op == ALU_PC8) ? x + 8 : 0;
endmodule