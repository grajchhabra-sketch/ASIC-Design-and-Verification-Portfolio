module decoder(input [31:0]instruction, output [6:0]opcode, output [4:0]rd, output [2:0]funct3,  output [4:0]rs1, output [4:0]rs2, output [6:0]funct7);
  
  assign opcode=instruction[6:0];
  assign rd=instruction[11:7];
  assign funct3=instruction[14:12];
  assign rs1=instruction[19:15];
  assign rs2=instruction[24:20];
  assign funct7=instruction[31:25];
endmodule

module register_file(input clk, input [4:0]rs1, input [4:0]rs2, input reg_write, input [4:0]rd, input [31:0]write_data, output [31:0]read_data1, output [31:0] read_data2);
  
  reg [31:0] regs [0:31];
  
 
    assign read_data1 = (rs1 == 5'd0)  ? 32'd0 : (reg_write && rd == rs1 && rd != 0) ? write_data : regs[rs1];


    assign read_data2 = (rs2 == 5'd0)  ? 32'd0 : (reg_write && rd == rs2 && rd != 0) ? write_data :  regs[rs2];
  
  //write port
  always@(posedge clk)
    begin
      if(reg_write && rd!=0)
        regs[rd]<=write_data;
    end
  
  property p_no_write_x0;
  @(posedge clk) disable iff(1'b0)
    !(reg_write && rd == 5'd0);
endproperty
assert property(p_no_write_x0)
  else $error("Illegal write attempted to x0");
  
endmodule

//immediate generator
module immediate_generator(input [31:0]instruction, output reg [31:0]imm_out);
  
  wire [6:0] opcode;
  assign opcode = instruction[6:0];
  
  always@(*)
    begin
      
      case(opcode)
        
        //I-type(ADDI, LW, JALR)
        7'b0010011,
        7'b0000011,
        7'b1100111:
          
          begin
            imm_out = {{20{instruction[31]}}, instruction[31:20]};
          end
        
        //S-type(SW)
        7'b0100011:
          begin
            imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
          end
        
        //B-type(BEQ, BNE)
        7'b1100011 :
          begin
            imm_out = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
          end
        
        //U-type(LUI, AUIPC)
        7'b0110111,
        7'b0010111:
          begin
            imm_out = {instruction[31:12],12'b0};
          end
        
        //J-type(JAL)
        7'b1101111:
        begin
          imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        end
        
        default:
          imm_out = 32'b0;
      endcase
    end
endmodule


module control_unit(
    input [6:0] opcode,
    input [4:0] rd,
    input [4:0] rs1,
    input [11:0] imm11_0,   // instruction[31:20], needed to detect addi x0,x0,0
    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        branch,
    output reg        jump,
    output reg  [1:0] alu_op
);
    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;
        case(opcode)
            // R-type
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            // I-type arithmetic
            7'b0010011: begin
                alu_src   = 1'b1;
                alu_op    = 2'b10;
                // NOP = addi x0, x0, 0 (encoding 00000013) must not write
                if (rd == 5'd0 && rs1 == 5'd0 && imm11_0 == 12'd0)
                    reg_write = 1'b0;
                else
                    reg_write = 1'b1;
            end
            // Load
            7'b0000011: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end
            // Store
            7'b0100011: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00;
            end
            // Branch
            7'b1100011: begin
                branch = 1'b1;
                alu_op = 2'b01;
            end
            // JAL
            7'b1101111: begin
                jump      = 1'b1;
                reg_write = 1'b1;
                alu_op    = 2'b00;
            end
            // JALR
            7'b1100111: begin
                jump      = 1'b1;
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end
            7'b0110111: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0010111: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b10;
            end
            7'b0001111: begin end
            default: begin
                reg_write  = 1'b0;
                alu_src    = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 2'b00;
            end
        endcase
    end
endmodule
