`timescale 1us/1us

`include "defs.sv"

module GeneralPurposeRegisters
(input GPR_in_t inst1, input GPR_in_t inst2, input clock, input reset, input first,
output GPR_out_t out1, output GPR_out_t out2);
    reg [31:0] regs[31:0];
    assign out1.read1 = regs[inst1.read1];
    assign out1.read2 = regs[inst1.read2];
    assign out2.read1 = regs[inst2.read1];
    assign out2.read2 = regs[inst2.read2];
    always_ff @(posedge clock) begin
        if(reset) begin
            for(integer i = 0; i < 32; i = i + 1)
                regs[i] <= 0;
        end
        else begin
            if(inst1.writeEnabled && inst2.writeEnabled && inst1.write == inst2.write) begin
                regs[inst1.write] <= (first == 0) ? inst2.writeData : inst1.writeData;
            end
            else begin
                if(inst1.writeEnabled)
                    regs[inst1.write] <= inst1.writeData;
                if(inst2.writeEnabled)
                    regs[inst2.write] <= inst2.writeData;
            end
        end
    end


endmodule