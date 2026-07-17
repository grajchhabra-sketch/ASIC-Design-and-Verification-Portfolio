class riscv_seq_item extends uvm_sequence_item;

    `uvm_object_utils(riscv_seq_item)

    rand bit [31:0] pc;
    rand bit [31:0] instruction;

    rand bit [31:0] wb_pc_plus4;
    rand bit [4:0]  wb_rd;
    rand bit        wb_reg_write;
    rand bit [31:0] write_back_data;

    rand bit        branch_taken;
    rand bit        jump;
    rand bit        stall;
    rand bit        flush;

    function new(string name = "riscv_seq_item");
        super.new(name);
    endfunction

endclass
