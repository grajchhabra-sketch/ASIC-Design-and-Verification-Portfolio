module bank_state 
#(
    parameter NUM_BANKS  = 8,
    parameter BANK_WIDTH = 3,
    parameter ROW_WIDTH  = 13
)
(
    input clk,
    input reset,

    input req_valid_i,
    input [BANK_WIDTH-1:0] bank_i,
    input [ROW_WIDTH-1:0] row_i,

    input act_cmd_i,
    input [BANK_WIDTH-1:0] act_bank_i,
    input [ROW_WIDTH-1:0] act_row_i,

    input pre_cmd_i,
    input [BANK_WIDTH-1:0] pre_bank_i,

    output reg row_hit_o,
    output reg row_miss_o,
    output reg row_conflict_o,

    output [NUM_BANKS-1:0] bank_open_valid_o,
    output [NUM_BANKS*ROW_WIDTH-1:0] bank_open_row_o
);

reg row_open_valid [0:NUM_BANKS-1];
reg [ROW_WIDTH-1:0] open_row [0:NUM_BANKS-1];

integer i;

genvar g;

generate
    for(g=0; g<NUM_BANKS; g=g+1) begin

        assign bank_open_valid_o[g] = row_open_valid[g];

        assign bank_open_row_o[g*ROW_WIDTH +: ROW_WIDTH] =
               open_row[g];

    end
endgenerate

always @(*) begin

    row_hit_o      = 1'b0;
    row_miss_o     = 1'b0;
    row_conflict_o = 1'b0;

    if(req_valid_i) begin

        if(!row_open_valid[bank_i])

            row_miss_o = 1'b1;

        else if(open_row[bank_i] == row_i)

            row_hit_o = 1'b1;

        else

            row_conflict_o = 1'b1;

    end

end

always @(posedge clk) begin

    if(reset) begin

        for(i=0;i<NUM_BANKS;i=i+1) begin

            row_open_valid[i] <= 1'b0;
            open_row[i] <= '0;

        end

    end
    else begin
              if(act_cmd_i) begin

            row_open_valid[act_bank_i] <= 1'b1;
            open_row[act_bank_i] <= act_row_i;

        end

        if(pre_cmd_i) begin

            row_open_valid[pre_bank_i] <= 1'b0;

        end

    end

end

property p_no_double_activate;
    @(posedge clk)
    disable iff(reset)
    act_cmd_i |-> !row_open_valid[act_bank_i];
endproperty

assert property(p_no_double_activate)
else
    $fatal(1,"ACT issued to an already open bank");

property p_no_precharge_closed_bank;
    @(posedge clk)
    disable iff(reset)
    pre_cmd_i |-> row_open_valid[pre_bank_i];
endproperty

assert property(p_no_precharge_closed_bank)
else
    $fatal(1,"PRE issued to a closed bank");

endmodule
  
  
