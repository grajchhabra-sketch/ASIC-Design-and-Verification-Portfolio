  module fr_fcfs_scheduler
#(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 128,
    parameter DEPTH       = 4,
    parameter BANK_WIDTH  = 3,
    parameter ROW_WIDTH   = 13,
    parameter COL_WIDTH   = 10,
    parameter RANK_WIDTH  = 3,
    parameter NUM_BANKS   = 8
)
(
    input clk,
    input reset,

    input                     fifo_valid_i,
    input                     fifo_write_i,
    input [ADDR_WIDTH-1:0]    fifo_addr_i,
    input [DATA_WIDTH-1:0]    fifo_wdata_i,

    output reg                pop_fifo_o,

    input [NUM_BANKS-1:0]             bank_open_valid_i,
    input [NUM_BANKS*ROW_WIDTH-1:0]   bank_open_row_i,

    input controller_ready_i,
    input sched_ready_i,

    output reg                  sched_valid_o,
    output reg                  sched_write_o,
    output reg [ADDR_WIDTH-1:0] sched_addr_o,
    output reg [DATA_WIDTH-1:0] sched_wdata_o,

    output reg [BANK_WIDTH-1:0] sched_bank_o,
    output reg [ROW_WIDTH-1:0]  sched_row_o,
    output reg [COL_WIDTH-1:0]  sched_col_o,
    output reg [RANK_WIDTH-1:0] sched_rank_o
);

reg                    valid_q [0:DEPTH-1];
reg                    write_q [0:DEPTH-1];

reg [ADDR_WIDTH-1:0]   addr_q  [0:DEPTH-1];
reg [DATA_WIDTH-1:0]   wdata_q [0:DEPTH-1];

reg [BANK_WIDTH-1:0]   bank_q  [0:DEPTH-1];
reg [ROW_WIDTH-1:0]    row_q   [0:DEPTH-1];
reg [COL_WIDTH-1:0]    col_q   [0:DEPTH-1];
reg [RANK_WIDTH-1:0]   rank_q  [0:DEPTH-1];

integer i;
integer slot;
integer selected;

reg found_hit;
reg [ROW_WIDTH-1:0] open_row;

wire [BANK_WIDTH-1:0] fifo_bank;
wire [ROW_WIDTH-1:0]  fifo_row;
wire [COL_WIDTH-1:0]  fifo_col;
wire [RANK_WIDTH-1:0] fifo_rank;

assign fifo_col  = fifo_addr_i[12:3];
assign fifo_bank = fifo_addr_i[15:13];
assign fifo_row  = fifo_addr_i[28:16];
assign fifo_rank = fifo_addr_i[31:29];

always @(posedge clk) begin

    if(reset) begin

        pop_fifo_o <= 1'b0;

        for(i=0;i<DEPTH;i=i+1) begin

            valid_q[i] <= 1'b0;
            write_q[i] <= 1'b0;

            addr_q[i]  <= '0;
            wdata_q[i] <= '0;

            bank_q[i]  <= '0;
            row_q[i]   <= '0;
            col_q[i]   <= '0;
            rank_q[i]  <= '0;

        end

    end
    else begin

        pop_fifo_o <= 1'b0;

        slot = -1;

        for(i=0;i<DEPTH;i=i+1) begin

            if((slot==-1) && !valid_q[i])

                slot = i;

        end

        if(fifo_valid_i && (slot!=-1)) begin

            valid_q[slot] <= 1'b1;
            write_q[slot] <= fifo_write_i;

            addr_q[slot]  <= fifo_addr_i;
            wdata_q[slot] <= fifo_wdata_i;

            bank_q[slot]  <= fifo_bank;
            row_q[slot]   <= fifo_row;
            col_q[slot]   <= fifo_col;
            rank_q[slot]  <= fifo_rank;

            pop_fifo_o <= 1'b1;

        end

    end

end
    always @(*) begin

    selected  = -1;
    found_hit = 1'b0;

    for(i=0;i<DEPTH;i=i+1) begin

        if(valid_q[i] && !found_hit) begin

            open_row = bank_open_row_i[
                bank_q[i]*ROW_WIDTH +: ROW_WIDTH
            ];

            if(bank_open_valid_i[bank_q[i]] &&
               (open_row == row_q[i])) begin

                selected  = i;
                found_hit = 1'b1;

            end

        end

    end

    if(!found_hit) begin

        for(i=0;i<DEPTH;i=i+1) begin

            if(valid_q[i] && (selected==-1))

                selected = i;

        end

    end

end

always @(*) begin

    sched_valid_o = 1'b0;
    sched_write_o = 1'b0;

    sched_addr_o  = '0;
    sched_wdata_o = '0;

    sched_bank_o  = '0;
    sched_row_o   = '0;
    sched_col_o   = '0;
    sched_rank_o  = '0;

    if(controller_ready_i && (selected!=-1)) begin

        sched_valid_o = 1'b1;
        sched_write_o = write_q[selected];

        sched_addr_o  = addr_q[selected];
        sched_wdata_o = wdata_q[selected];

        sched_bank_o  = bank_q[selected];
        sched_row_o   = row_q[selected];
        sched_col_o   = col_q[selected];
        sched_rank_o  = rank_q[selected];

    end

end

always @(posedge clk) begin

    if(!reset) begin

        if(sched_valid_o &&
           sched_ready_i &&
           (selected!=-1)) begin

            for(i=selected;i<DEPTH-1;i=i+1) begin

                valid_q[i] <= valid_q[i+1];
                write_q[i] <= write_q[i+1];

                addr_q[i]  <= addr_q[i+1];
                wdata_q[i] <= wdata_q[i+1];

                bank_q[i]  <= bank_q[i+1];
                row_q[i]   <= row_q[i+1];
                col_q[i]   <= col_q[i+1];
                rank_q[i]  <= rank_q[i+1];

            end

            valid_q[DEPTH-1] <= 1'b0;
            write_q[DEPTH-1] <= 1'b0;

            addr_q[DEPTH-1]  <= '0;
            wdata_q[DEPTH-1] <= '0;

            bank_q[DEPTH-1]  <= '0;
            row_q[DEPTH-1]   <= '0;
            col_q[DEPTH-1]   <= '0;
            rank_q[DEPTH-1]  <= '0;

        end

    end

end

property p_sched_when_ready;

    @(posedge clk)
    disable iff(reset)

    sched_valid_o |-> controller_ready_i;

endproperty

assert property(p_sched_when_ready)
else
    $fatal(1,"Scheduler issued request when controller not ready");

property p_selected_valid;

    @(posedge clk)
    disable iff(reset)

    (sched_valid_o && (selected!=-1)) |-> valid_q[selected];

endproperty

assert property(p_selected_valid)
else
    $fatal(1,"Scheduler selected invalid request");
  
  always @(posedge clk) begin
    if(pop_fifo_o)
        $display("[%0t] FIFO POP", $time);

    if(sched_valid_o)
        $display("[%0t] SCHED VALID", $time);
end

endmodule
