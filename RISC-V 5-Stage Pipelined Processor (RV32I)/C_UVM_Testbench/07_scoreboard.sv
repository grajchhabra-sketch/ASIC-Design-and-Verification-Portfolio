class riscv_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(riscv_scoreboard)

    uvm_analysis_imp #(riscv_seq_item,riscv_scoreboard) analysis_export;

    bit [31:0] last_pc;
    int        repeat_count;

    function new(string name="riscv_scoreboard", uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export",this);
        last_pc = 32'hFFFFFFFF;
        repeat_count = 0;
    endfunction

    virtual function void write(riscv_seq_item tr);

        if(!(tr.wb_reg_write || tr.branch_taken || tr.jump || tr.stall))
            return;

        // Hang detection
        if (tr.pc == last_pc) begin
            repeat_count++;
            if (repeat_count > 20) begin
                `uvm_fatal("HANG",
                $sformatf("PC stuck at %h for %0d cycles - infinite loop detected",
                tr.pc, repeat_count))
            end
        end else begin
            repeat_count = 0;
            last_pc = tr.pc;
        end

`uvm_info("SCOREBOARD", $sformatf("PC=%h INSTR=%h WB_RD=x%0d WB_DATA=%h WB_WE=%0b STALL=%0b FLUSH=%0b", tr.pc, tr.instruction, tr.wb_rd, tr.write_back_data, tr.wb_reg_write, tr.stall, tr.flush), UVM_LOW)

        if(tr.wb_reg_write) begin
            if(tr.wb_rd==0)
                `uvm_error("WRITEBACK", "Attempt to write x0")
            else
                `uvm_info("WRITEBACK",
                $sformatf("PASS : x%0d <= %h", tr.wb_rd, tr.write_back_data),
                UVM_LOW);
        end

        if(tr.branch_taken || tr.jump)
            `uvm_info("CONTROL",
            $sformatf("Branch=%0b Jump=%0b Flush=%0b",
            tr.branch_taken, tr.jump, tr.flush),
            UVM_LOW);

        if(tr.stall)
            `uvm_info("HAZARD", "Load-use hazard stall detected", UVM_LOW);

    endfunction

endclass
