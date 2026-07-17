class riscv_driver extends uvm_driver #(riscv_seq_item);

    `uvm_component_utils(riscv_driver)

    virtual riscv_if vif;

    function new(string name = "riscv_driver", uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual riscv_if)::get(this,"","vif",vif))
            `uvm_fatal("DRIVER","Virtual Interface Not Found")

    endfunction

    task run_phase(uvm_phase phase);

        riscv_seq_item tr;

        vif.reset <= 1'b1;

        repeat(2)
            @(posedge vif.clk);

        vif.reset <= 1'b0;

        forever begin

            seq_item_port.get_next_item(tr);

            @(posedge vif.clk);

            seq_item_port.item_done();

        end

    endtask

endclass
