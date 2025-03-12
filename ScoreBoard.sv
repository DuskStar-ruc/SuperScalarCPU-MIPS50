`timescale 1us/1us

`include "defs.sv"

typedef struct packed{
    logic [1:0] wbtime; // 距写回剩余的时钟周期
    logic line_id; // 写回来源流水�??
    stage_t source_stage; // 写回来源阶段
} SB_data_t; // ScoreBoard data type

module ForwardingUnit
(input SB_data_t data, input stage_t use_stage,
output forward_t forward, output block);
    // 以下逻辑为卡诺图化简结果，可能不具有常规逻辑意义
    assign forward.source.line = data.line_id;
    assign forward.source.stage = (data.source_stage == EX_STAGE && data.wbtime >= 2) ?
                                         EX_STAGE : MEM_STAGE;
    assign forward.target = ((data.source_stage == EX_STAGE && data.wbtime == 2) || data.wbtime == 1) ?
                            EX_STAGE : MEM_STAGE;
    assign forward.need_forward = data.wbtime != 0;
    assign block = ((data.source_stage == MEM_STAGE || use_stage == EX_STAGE) && data.wbtime == 3) ||
                    (data.source_stage == MEM_STAGE && use_stage == EX_STAGE && data.wbtime == 2);
endmodule

module ScoreBoard
(input SB_in_t inst1,input SB_in_t inst2, input clock, input reset,
output SB_out_t out1, output SB_out_t out2, output first);
    SB_data_t regdata[32], lockregdata[4];
    reg [3:0] mdu_time;
    reg blockflag[2];
    reg fakewbflag[2];
    reg firstline;
    reg[4:0] newreg[2];
    SB_data_t newregdata[2], newlockregdata[4];
    reg blockspflag[2];
    wire newblockflag[2], issueflag[2], mdublock[2];
    wire newfirstline;

    function SB_data_t next(SB_data_t data);
        SB_data_t nextdata;
        nextdata.wbtime = data.wbtime ? data.wbtime - 1 : 0;
        nextdata.line_id = data.line_id;
        nextdata.source_stage = data.source_stage;
        return nextdata;
    endfunction

    SB_data_t tempdata[4];
    forward_t tempforward[4];
    wire tempblock[4];
    ForwardingUnit fu0(.data(tempdata[0]), .use_stage(inst1.rs_stage),
                       .forward(tempforward[0]), .block(tempblock[0]));
    ForwardingUnit fu1(.data(tempdata[1]), .use_stage(inst1.rt_stage),
                       .forward(tempforward[1]), .block(tempblock[1]));
    ForwardingUnit fu2(.data(tempdata[2]), .use_stage(inst1.rs_stage),
                       .forward(tempforward[2]), .block(tempblock[2]));
    ForwardingUnit fu3(.data(tempdata[3]), .use_stage(inst1.rt_stage),
                       .forward(tempforward[3]), .block(tempblock[3]));

    assign newregdata[0] = {2'b11, 1'b0, inst1.rw_stage};
    assign newregdata[1] = {2'b11, 1'b1, inst2.rw_stage};
    assign tempdata[0] = (newreg[1] == inst1.rs && newreg[1] && !fakewbflag[1]) ? newregdata[1] :
                         blockflag[0] ? lockregdata[0] : regdata[inst1.rs];
    assign tempdata[1] = (newreg[1] == inst1.rt && newreg[1] && !fakewbflag[1]) ? newregdata[1] :
                         blockflag[0] ? lockregdata[1] : regdata[inst1.rt];
    assign tempdata[2] = (newreg[0] == inst2.rs && newreg[0] && !fakewbflag[0]) ? newregdata[0] :
                          blockflag[1] ? lockregdata[2] : regdata[inst2.rs];
    assign tempdata[3] = (newreg[0] == inst2.rt && newreg[0] && !fakewbflag[0]) ? newregdata[0] :
                          blockflag[1] ? lockregdata[3] : regdata[inst2.rt];
    assign mdublock[0] = (inst1.mdu_use != MDU_NONE) && 
                        ((mdu_time > 1 && inst1.mdu_use == MDU_READ) ||
                         (mdu_time && inst1.mdu_use != MDU_READ) ||
                         (firstline == 1 && inst2.mdu_use != MDU_NONE));
    assign mdublock[1] = (inst2.mdu_use != MDU_NONE) &&
                        ((mdu_time > 1 && inst2.mdu_use == MDU_READ) ||
                         (mdu_time && inst2.mdu_use != MDU_READ) ||
                         (firstline == 0 && inst1.mdu_use != MDU_NONE));
    assign issueflag[0] = !(tempblock[0] || tempblock[1] || mdublock[0] || blockspflag[0]);
    assign newblockflag[0] = ((tempblock[0] || tempblock[1] || mdublock[0]) && !blockspflag[0]) ? 1 : 0;
    assign newlockregdata[0] = (newblockflag[0]) ? next(tempdata[0]) : 0;
    assign newlockregdata[1] = (newblockflag[0]) ? next(tempdata[1]) : 0;
    assign issueflag[1] = !(tempblock[2] || tempblock[3] || mdublock[1] || blockspflag[1]);
    assign newblockflag[1] = ((tempblock[2] || tempblock[3] || mdublock[1]) && !blockspflag[1]) ? 1 : 0;
    assign newlockregdata[2] = (newblockflag[1]) ? next(tempdata[2]) : 0;
    assign newlockregdata[3] = (newblockflag[1]) ? next(tempdata[3]) : 0;
    assign newfirstline = (issueflag[0] && !issueflag[1])? 1 :
                        (issueflag[1] && !issueflag[0])? 0 :
                        (issueflag[0] && issueflag[1])? 0 : firstline;
    assign out1 = {!issueflag[0], fakewbflag[0], tempforward[0], tempforward[1]};
    assign out2 = {!issueflag[1], fakewbflag[1], tempforward[2], tempforward[3]};
    assign first = firstline;
    always_comb begin
        if(firstline == 0) begin
            newreg[1] = 0;
            blockspflag[0] = 0;
            newreg[0] = issueflag[0] ? inst1.rw : 0;
            blockspflag[1] = newblockflag[0] && 
                               ((inst1.special && inst2.special) ||
                                (inst1.rw && (inst1.rw == inst2.rs || inst1.rw == inst2.rt)) ||
                                (inst1.mdu_use != MDU_NONE && mdu_time > 2 && 
                                (inst1.rs && inst1.rs == inst2.rw) || (inst1.rt && inst1.rt == inst2.rw)));
        end
        else begin
            newreg[0] = 0;
            blockspflag[1] = 0;
            newreg[1] = issueflag[1] ? inst2.rw : 0;
            blockspflag[0] = newblockflag[1] && 
                               ((inst2.special && inst1.special) ||
                                (inst2.rw && (inst2.rw == inst1.rs || inst2.rw == inst1.rt)) ||
                                (inst2.mdu_use != MDU_NONE && mdu_time > 2 &&
                                (inst2.rs && inst2.rs == inst1.rw) || (inst2.rt && inst2.rt == inst1.rw)));
        end
    end

    always_ff @(negedge clock) begin
        if(reset) begin
            firstline <= 0;
            for(int i = 0; i < 32; i++)
                regdata[i] <= 0;
            for(int i = 0; i < 4; i++)
                lockregdata[i] <= 0;
            for(int i = 0; i < 2; i++)
            begin
                blockflag[i] <= 0;
                fakewbflag[i] <= 0;
            end
            mdu_time <= 0;
        end
        else begin
            firstline <= newfirstline;
            if(inst1.rw && (inst1.rw == inst2.rw) && issueflag[0] && issueflag[1])
                regdata[inst1.rw] <= next(firstline ? newregdata[0] : newregdata[1]);
            else begin
                if(issueflag[0] && inst1.rw && !fakewbflag[0])
                    regdata[inst1.rw] <= next(newregdata[0]);
                if(issueflag[1] && inst2.rw && !fakewbflag[1])
                    regdata[inst2.rw] <= next(newregdata[1]);
            end
            for(int i = 0; i < 32; i++) begin
                if((i != inst1.rw || !issueflag[0]) && (i != inst2.rw ||!issueflag[1]))
                    regdata[i] <= next(regdata[i]);
            end
            lockregdata[0] <= issueflag[0] ? 0 : newlockregdata[0];
            lockregdata[1] <= issueflag[0] ? 0 : newlockregdata[1];
            lockregdata[2] <= issueflag[1] ? 0 : newlockregdata[2];
            lockregdata[3] <= issueflag[1] ? 0 : newlockregdata[3];
            blockflag[0] <= newblockflag[0];
            blockflag[1] <= newblockflag[1];
            if(issueflag[0])
                fakewbflag[0] <= 0;
            else if(inst1.rw && (inst1.rw == inst2.rw) && issueflag[1] && firstline==0)
                fakewbflag[0] <= 1;
            if(issueflag[1])
                fakewbflag[1] <= 0;
            else if(inst1.rw && (inst1.rw == inst2.rw) && issueflag[0] && firstline==1)
                fakewbflag[1] <= 1;
            if(mdu_time)
                mdu_time <= mdu_time - 1;
            else if(inst1.mdu_use != MDU_NONE && issueflag[0])
                mdu_time <= inst1.mdu_use == MDU_MUL ? `MUL_DELAY_CYCLES :
                            inst1.mdu_use == MDU_DIV ? `DIV_DELAY_CYCLES : 0;
            else if(inst2.mdu_use != MDU_NONE && issueflag[1])
                mdu_time <= inst2.mdu_use == MDU_MUL ? `MUL_DELAY_CYCLES :
                            inst2.mdu_use == MDU_DIV ? `DIV_DELAY_CYCLES : 0;
        end
    end
endmodule

