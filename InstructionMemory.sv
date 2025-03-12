`timescale 1us/1us

`include "defs.sv"

module InstructionMemory
(input [31:0] addr1, input [31:0] addr2,
output [31:0] inst1, output [31:0] inst2);
    reg [31:0] memory [1023:0];
    assign inst1 = memory[addr1[11:2]];
    assign inst2 = memory[addr2[11:2]];
    initial
        $readmemh("./code.txt", memory);
endmodule
