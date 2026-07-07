class axi_transaction extends uvm_sequence_item;

    rand bit awvalid;
    rand bit [31:0] awaddr;

    rand bit wvalid;
    rand bit [31:0] wdata;

    rand bit arvalid;
    rand bit [31:0] araddr;

    rand bit bready;
    rand bit rready;

    rand bit [1:0] aw_region;
    rand bit [1:0] ar_region;

    `uvm_object_utils(axi_transaction)

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    constraint c_rw
    {
        awvalid dist {1:=50,0:=50};

        if(awvalid)
            arvalid == 0;
        else
            arvalid == 1;
    }

    constraint c_wvalid
    {
        if(awvalid)
            wvalid == 1;
        else
            wvalid == 0;
    }

    constraint c_ready
    {
        bready dist {1:=80,0:=20};
        rready dist {1:=80,0:=20};
    }

    constraint c_region
    {
        aw_region inside {0,1,2};
        ar_region inside {0,1,2};
    }

    constraint c_data
    {
        wdata dist {
            [32'h00000000:32'h3FFFFFFF] := 25,
            [32'h40000000:32'h7FFFFFFF] := 25,
            [32'h80000000:32'hBFFFFFFF] := 25,
            [32'hC0000000:32'hFFFFFFFF] := 25
        };
    }

    function void post_randomize();

        case(aw_region)

            0:
                awaddr = ($urandom_range(0,32'h00000FFF))
                         & 32'hFFFFFFFC;

            1:
                awaddr = (32'h00001000 +
                         $urandom_range(0,32'h0000EFFF))
                         & 32'hFFFFFFFC;

            2:
                awaddr = (32'h00010000 +
                         $urandom_range(0,32'h0000FFFF))
                         & 32'hFFFFFFFC;

        endcase


        case(ar_region)

            0:
                araddr = ($urandom_range(0,32'h00000FFF))
                         & 32'hFFFFFFFC;

            1:
                araddr = (32'h00001000 +
                         $urandom_range(0,32'h0000EFFF))
                         & 32'hFFFFFFFC;

            2:
                araddr = (32'h00010000 +
                         $urandom_range(0,32'h0000FFFF))
                         & 32'hFFFFFFFC;

        endcase

    endfunction

    function void display();

        if(awvalid)
            $display("WRITE ADDR=%h DATA=%h",awaddr,wdata);
        else
            $display("READ ADDR=%h",araddr);

    endfunction

endclass
