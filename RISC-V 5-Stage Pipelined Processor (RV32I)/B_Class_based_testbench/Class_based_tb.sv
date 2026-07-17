interface riscv_if;

    logic clk;
    logic reset;

    logic [31:0] pc_curr;
    logic [31:0] if_instruction;

    logic [31:0] wb_pc_plus4;
    logic [4:0]  wb_rd;
    logic        wb_reg_write;
    logic [31:0] write_back_data;

    logic        branch_taken;
    logic        ex_jump;
    logic        hazard_stall;
    logic        ctrl_flush;

endinterface


class riscv_tx;

    bit [31:0] pc;
    bit [31:0] instruction;

    bit [31:0] wb_pc_plus4;
    bit [4:0]  wb_rd;
    bit        wb_reg_write;
    bit [31:0] write_back_data;

    bit        branch_taken;
    bit        jump;
    bit        stall;
    bit        flush;

    
    function void display();
        $display("PC=%h INSTR=%h WB_RD=%0d WB_DATA=%h WB_WE=%0b STALL=%0b FLUSH=%0b",
                  pc, instruction, wb_rd, write_back_data, wb_reg_write, stall, flush);
    endfunction

endclass

class driver;

    virtual riscv_if vif;

    function new(virtual riscv_if vif);
        this.vif = vif;
    endfunction

    task run();

        vif.reset <= 1'b1;
        repeat(2) @(posedge vif.clk);
        vif.reset <= 1'b0;

        forever @(posedge vif.clk);

    endtask

endclass




class generator;

    int num_cycles = 30000;

    function new();
    endfunction

    task run();
        repeat(num_cycles) begin
        end
    endtask

endclass




class monitor;
    virtual riscv_if vif;
    mailbox #(riscv_tx) mon2scb;
    mailbox #(riscv_tx) mon2cov;

    function new(virtual riscv_if vif,
                 mailbox #(riscv_tx) mon2scb,
                 mailbox #(riscv_tx) mon2cov);
        this.vif     = vif;
        this.mon2scb = mon2scb;
        this.mon2cov = mon2cov;
    endfunction

    task run();
        riscv_tx tx;
        wait(vif.reset == 0);
        forever begin
            @(posedge vif.clk);
            #1; 

            tx = new();
            tx.pc              = vif.pc_curr;
            tx.instruction     = vif.if_instruction;
            tx.wb_pc_plus4     = vif.wb_pc_plus4;
            tx.wb_rd           = vif.wb_rd;
            tx.wb_reg_write    = vif.wb_reg_write;
            tx.write_back_data = vif.write_back_data;
            tx.branch_taken    = vif.branch_taken;
            tx.jump            = vif.ex_jump;
            tx.stall           = vif.hazard_stall;
            tx.flush           = vif.ctrl_flush;

            mon2scb.put(tx);
            mon2cov.put(tx);
        end
    endtask
endclass





class scoreboard;

    mailbox #(riscv_tx) mon2scb;

    function new(mailbox #(riscv_tx) mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    task run();

        riscv_tx tx;

        forever begin

            mon2scb.get(tx);

            if (tx.wb_reg_write ||
                tx.branch_taken ||
                tx.jump ||
                tx.stall) begin

                $display(" SCOREBOARD");

                tx.display();

          
                if (tx.wb_reg_write) begin

                    if (tx.wb_rd == 5'd0)
                        $error("FAIL : Illegal write to x0");

                    else begin
                        $display("WRITEBACK PASS");
                        $display("rd   = x%0d", tx.wb_rd);
                        $display("data = %h", tx.write_back_data);
                    end

                end

            
                if (tx.branch_taken || tx.jump) begin

                    $display("CONTROL FLOW EVENT");
                    $display("Branch Taken : %0b", tx.branch_taken);
                    $display("Jump         : %0b", tx.jump);
                    $display("Flush        : %0b", tx.flush);

                end

         
                if (tx.stall) begin

                    $display("HAZARD STALL DETECTED");

                end


            end

        end

    endtask

endclass


class coverage;

    mailbox #(riscv_tx) mon2cov;
    riscv_tx tx;

    covergroup riscv_cg;
        option.per_instance = 1;

        cp_opcode : coverpoint tx.instruction[6:0] {
            bins r_type   = {7'b0110011};
            bins i_type   = {7'b0010011};
            bins load     = {7'b0000011};
            bins store    = {7'b0100011};
            bins branch   = {7'b1100011};
            bins jal      = {7'b1101111};
            bins jalr     = {7'b1100111};
            bins lui      = {7'b0110111};
            bins auipc    = {7'b0010111};
        }

        cp_stall : coverpoint tx.stall {
            bins stalled     = {1};
            bins not_stalled = {0};
        }

        cp_flush : coverpoint tx.flush {
            bins flushed     = {1};
            bins not_flushed = {0};
        }

        cp_branch_taken : coverpoint tx.branch_taken {
            bins taken     = {1};
            bins not_taken = {0};
        }

        cp_jump : coverpoint tx.jump {
            bins jumped     = {1};
            bins not_jumped = {0};
        }

        cp_wb_we : coverpoint tx.wb_reg_write {
            bins write     = {1};
            bins not_write = {0};
        }

        cross cp_opcode, cp_stall;
        cross cp_opcode, cp_flush;
        cross cp_branch_taken, cp_flush;

    endgroup

    function new(mailbox #(riscv_tx) mon2cov);
        this.mon2cov = mon2cov;
        riscv_cg = new();
    endfunction

    task run();
        forever begin
            mon2cov.get(tx);
            riscv_cg.sample();
        end
    endtask

    function void report();
        $display("FUNCTIONAL COVERAGE = %0.2f %%", riscv_cg.get_coverage());
        $display("cp_opcode        = %0.2f", riscv_cg.cp_opcode.get_coverage());
        $display("cp_stall         = %0.2f", riscv_cg.cp_stall.get_coverage());
        $display("cp_flush         = %0.2f", riscv_cg.cp_flush.get_coverage());
        $display("cp_branch_taken  = %0.2f", riscv_cg.cp_branch_taken.get_coverage());
        $display("cp_jump          = %0.2f", riscv_cg.cp_jump.get_coverage());
        $display("cp_wb_we         = %0.2f", riscv_cg.cp_wb_we.get_coverage());
    endfunction

endclass



class environment;

    generator   gen;
    driver      drv;
    monitor     mon;
    scoreboard  scb;
    coverage    cov;

    mailbox #(riscv_tx) mon2scb;
    mailbox #(riscv_tx) mon2cov;

    virtual riscv_if vif;

    function new(virtual riscv_if vif);

        this.vif = vif;

        mon2scb = new();
        mon2cov = new();

        gen = new();
        drv = new(vif);
        mon = new(vif, mon2scb, mon2cov);
        scb = new(mon2scb);
        cov = new(mon2cov);

    endfunction

    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
            cov.run();
        join_none
    endtask

endclass




class test;

    environment env;

    virtual riscv_if vif;

    function new(virtual riscv_if vif);
        this.vif = vif;
        env = new(vif);
    endfunction

    task run();
        $display(" RISC-V PIPELINE TEST STARTED");
        env.run();
    endtask

    function void report();
        env.cov.report();
    endfunction

endclass


module tb_top;

    riscv_if vif();

    riscv_top dut(
        .clk   (vif.clk),
        .reset (vif.reset)
    );

    assign vif.pc_curr         = dut.pc_curr;
    assign vif.if_instruction  = dut.if_instruction;

    assign vif.wb_pc_plus4     = dut.wb_pc_plus4;
    assign vif.wb_rd           = dut.wb_rd;
    assign vif.wb_reg_write    = dut.wb_reg_write;
    assign vif.write_back_data = dut.write_back_data;

    assign vif.branch_taken    = dut.branch_taken;
    assign vif.ex_jump         = dut.ex_jump;
    assign vif.hazard_stall    = dut.hazard_stall;
    assign vif.ctrl_flush      = dut.ctrl_flush;

    test t;

    initial begin
        vif.clk = 0;
        forever #5 vif.clk = ~vif.clk;
    end

    initial begin
        t = new(vif);
        t.run();
    end

    initial begin
        #10000;
        t.report();
        $display("\nSimulation Finished");
        $finish;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
