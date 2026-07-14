
//forwarding
module forwarding_unit(

    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,

    input [4:0] ex_mem_rd,
    input       ex_mem_reg_write,

    input [4:0] mem_wb_rd,
    input       mem_wb_reg_write,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b

);

always @(*)
begin

  
    forward_a = 2'b00;
    forward_b = 2'b00;


    if(ex_mem_reg_write &&
       (ex_mem_rd != 0) &&
       (ex_mem_rd == id_ex_rs1))
    begin
        forward_a = 2'b10;
    end

    if(ex_mem_reg_write &&
       (ex_mem_rd != 0) &&
       (ex_mem_rd == id_ex_rs2))
    begin
        forward_b = 2'b10;
    end

    
    if(mem_wb_reg_write &&
       (mem_wb_rd != 0) &&
       !(ex_mem_reg_write &&
         (ex_mem_rd != 0) &&
         (ex_mem_rd == id_ex_rs1)) &&
       (mem_wb_rd == id_ex_rs1))
    begin
        forward_a = 2'b01;
    end

    if(mem_wb_reg_write &&
       (mem_wb_rd != 0) &&
       !(ex_mem_reg_write &&
         (ex_mem_rd != 0) &&
         (ex_mem_rd == id_ex_rs2)) &&
       (mem_wb_rd == id_ex_rs2))
    begin
        forward_b = 2'b01;
    end

end

endmodule
//hazard detection
module hazard_detection_unit(

    input       id_ex_mem_read,
    input [4:0] id_ex_rd,

    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,

    output reg stall,
    output reg pc_write,
    output reg if_id_write

);

always @(*)
begin

    if (id_ex_mem_read &&
    (id_ex_rd != 5'd0) &&
    ((id_ex_rd == if_id_rs1) ||
     (id_ex_rd == if_id_rs2)))
    begin

        stall      = 1'b1;
        pc_write   = 1'b0;
        if_id_write= 1'b0;

    end

    else
    begin

        stall      = 1'b0;
        pc_write   = 1'b1;
        if_id_write= 1'b1;

    end

end
  
 

endmodule

//flush
module flush_unit(

    input branch_taken,
    input jump,

    output flush

);

assign flush = branch_taken | jump;


endmodule

//forwarding mux a
module forward_mux_a(

    input [31:0] read_data1,
    input [31:0] ex_mem_data,
    input [31:0] mem_wb_data,

    input [1:0] forward_a,

    output reg [31:0] operand_a

);

always @(*)
begin

    case(forward_a)

        2'b00:
            operand_a = read_data1;

        2'b10:
            operand_a = ex_mem_data;

        2'b01:
            operand_a = mem_wb_data;

        default:
            operand_a = read_data1;

    endcase

end

endmodule

//forwarding mux b
module forward_mux_b(

    input [31:0] read_data2,
    input [31:0] ex_mem_data,
    input [31:0] mem_wb_data,

    input [1:0] forward_b,

    output reg [31:0] operand_b

);

always @(*)
begin

    case(forward_b)

        2'b00:
            operand_b = read_data2;

        2'b10:
            operand_b = ex_mem_data;

        2'b01:
            operand_b = mem_wb_data;

        default:
            operand_b = read_data2;

    endcase

end

endmodule

