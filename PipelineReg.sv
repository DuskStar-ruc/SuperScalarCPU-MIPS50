`timescale 1us/1us

`include "defs.sv"

module PipelineReg (input PipelineReg_t in, input clock, input reset, output PipelineReg_t out);
    PipelineReg_t pipelinereg;
    assign out = pipelinereg;
    always_ff @(negedge clock) begin
        if (reset) begin
            pipelinereg = 0;
        end else begin
            pipelinereg = in;
        end
    end
endmodule