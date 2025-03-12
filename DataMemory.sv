`timescale 1us/1us

`include "defs.sv"

module DataMemory
(input DM_in_t inst_1, input DM_in_t inst_2, input clock, input reset, input first,
output DM_out_t out_1, output DM_out_t out_2);
    reg [31:0] data[2047:0];
    wire [31:0] readword[2];
    wire [15:0] readhalf[2];
    wire [7:0] readbyte[2];
    wire [5:0] tempAddr[2];
    DM_in_t inst_fir, inst_sec;
    DM_out_t out_fir, out_sec;

    assign inst_fir = (first==0) ? inst_1 : inst_2;
    assign inst_sec = (first==0) ? inst_2 : inst_1;
    assign out_1 = (first==0) ? out_fir : out_sec;
    assign out_2 = (first==0) ? out_sec : out_fir;
    
    assign readword[0] = data[inst_fir.address[12:2]];
    assign readword[1] = data[inst_sec.address[12:2]];
    assign readhalf[0] = inst_fir.address[1] ? readword[0][31:16] : readword[0][15:0];
    assign readhalf[1] = inst_sec.address[1] ? readword[1][31:16] : readword[1][15:0];
    assign readbyte[0] = inst_fir.address[0] ? readhalf[0][15:8] : readhalf[0][7:0];
    assign readbyte[1] = inst_sec.address[0] ? readhalf[1][15:8] : readhalf[1][7:0];
    assign tempAddr[0] = inst_fir.address[1:0] << 3;
    assign tempAddr[1] = inst_sec.address[1:0] << 3;
    assign out_fir.result = (inst_fir.size == DM_WORD) ? readword[0] :
                        (inst_fir.size == DM_HALF && inst_fir.readSigned)  ? {{16{readhalf[0][15]}}, readhalf[0]} :
                        (inst_fir.size == DM_HALF && !inst_fir.readSigned) ? {16'b0, readhalf[0]} :
                        (inst_fir.size == DM_BYTE && inst_fir.readSigned)  ? {{24{readbyte[0][7]}}, readbyte[0]} :
                        (inst_fir.size == DM_BYTE && !inst_fir.readSigned) ? {24'b0, readbyte[0]} : 0;
    assign out_sec.result = (inst_sec.size == DM_WORD) ? readword[1] :
                        (inst_sec.size == DM_HALF && inst_sec.readSigned)  ? {{16{readhalf[1][15]}}, readhalf[1]} :
                        (inst_sec.size == DM_HALF && !inst_sec.readSigned) ? {16'b0, readhalf[1]} :
                        (inst_sec.size == DM_BYTE && inst_sec.readSigned)  ? {{24{readbyte[1][7]}}, readbyte[1]} :
                        (inst_sec.size == DM_BYTE && !inst_sec.readSigned) ? {24'b0, readbyte[1]} : 0;
    assign out_fir.writeAddr = inst_fir.address[12:2] << 2;
    assign out_sec.writeAddr = inst_sec.address[12:2] << 2;
    always_comb begin
        out_fir.writeData = data[inst_fir.address[12:2]];
        if(inst_fir.size == DM_WORD)
            out_fir.writeData = inst_fir.writeInput;
        else if(inst_fir.size == DM_HALF)
            out_fir.writeData[(tempAddr[0] + 15)-:16] = inst_fir.writeInput[15:0];
        else if(inst_fir.size == DM_BYTE)
            out_fir.writeData[(tempAddr[0] + 7)-:8] = inst_fir.writeInput[7:0];
    end
    always_comb begin
        out_sec.writeData = data[inst_sec.address[12:2]];
        if(inst_sec.size == DM_WORD)
            out_sec.writeData = inst_sec.writeInput;
        else if(inst_sec.size == DM_HALF)
            out_sec.writeData[(tempAddr[1] + 15)-:16] = inst_sec.writeInput[15:0];
        else if(inst_sec.size == DM_BYTE)
            out_sec.writeData[(tempAddr[1] + 7)-:8] = inst_sec.writeInput[7:0];
    end

    always @(posedge clock) begin
        if(reset) begin
            for(integer i = 0; i < 2048; i = i + 1)
                data[i] <= 0;
        end
        else begin
            if(inst_fir.writeEnabled)
                data[inst_fir.address[12:2]] <= out_fir.writeData;
        end
    end
    always @(negedge clock) begin
        if(!reset) begin
            if(inst_sec.writeEnabled)
                data[inst_sec.address[12:2]] <= out_sec.writeData;
        end
    end
endmodule