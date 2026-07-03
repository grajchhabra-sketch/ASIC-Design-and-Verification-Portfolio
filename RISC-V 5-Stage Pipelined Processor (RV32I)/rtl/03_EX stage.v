module alu_control(
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input  [6:0] funct7,
    input        alu_src,

    output reg [3:0] alu_ctrl
);

    always @(*) begin
        case(alu_op)

            2'b00: alu_ctrl = 4'b0000; 

            2'b01: alu_ctrl = 4'b0001; 

            2'b10: begin
                case(funct3)
                    3'b000: begin
                        if (funct7[5] == 1'b1 && alu_src == 1'b0)
                            alu_ctrl = 4'b0001; // SUB
                        else
                            alu_ctrl = 4'b0000; // ADD / ADDI
                    end
                    3'b111: alu_ctrl = 4'b0010; // AND / ANDI
                    3'b110: alu_ctrl = 4'b0011; // OR  / ORI
                    3'b100: alu_ctrl = 4'b0100; // XOR / XORI
                    3'b010: alu_ctrl = 4'b0101; // SLT / SLTI
                    3'b011: alu_ctrl = 4'b1001; // SLTU / SLTIU
                    3'b001: alu_ctrl = 4'b0110; // SLL / SLLI
                    3'b101: begin
                        if (funct7[5] == 1'b1)
                            alu_ctrl = 4'b1000; // SRA / SRAI
                        else
                            alu_ctrl = 4'b0111; // SRL / SRLI
                    end
                    default: alu_ctrl = 4'b0000;
                endcase
            end

          
            2'b11: begin

                alu_ctrl = 4'b1011; // pass operand_b only
            end

            default: alu_ctrl = 4'b0000;
        endcase
    end

endmodule
//ALU
module alu(
    input  [31:0] operand_a,
    input  [31:0] operand_b,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result,
    output            zero
);

    always @(*) begin
        case(alu_ctrl)
            4'b0000: result = operand_a + operand_b;                        // ADD / ADDI / AUIPC / JALR
            4'b0001: result = operand_a - operand_b;                        // SUB
            4'b0010: result = operand_a & operand_b;                        // AND / ANDI
            4'b0011: result = operand_a | operand_b;                        // OR  / ORI
            4'b0100: result = operand_a ^ operand_b;                        // XOR / XORI
            4'b0101: result = ($signed(operand_a) < $signed(operand_b))
                              ? 32'd1 : 32'd0;                              // SLT / SLTI
            4'b0110: result = operand_a << operand_b[4:0];                  // SLL / SLLI
            4'b0111: result = operand_a >> operand_b[4:0];                  // SRL / SRLI
            4'b1000: result = $signed(operand_a) >>> operand_b[4:0];        // SRA / SRAI
            4'b1001: result = (operand_a < operand_b)
                              ? 32'd1 : 32'd0;                              // SLTU / SLTIU
            4'b1011: result = operand_b;                                    // LUI (pass upper imm)
            default: result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
//ALU MUX
module alu_src_mux(

    input  [31:0] rs2_data,
    input  [31:0] imm_data,

    input         alu_src,

    output [31:0] operand_b

);

assign operand_b = (alu_src) ? imm_data : rs2_data;

endmodule


//Branch Logic
module branch_logic(

    input        branch,
    input [2:0]  funct3,

    input [31:0] rs1_data,
    input [31:0] rs2_data,

    output reg branch_taken

);

always @(*)
begin

    branch_taken = 1'b0;

    if(branch)
    begin

        case(funct3)

            // BEQ
            3'b000:
                branch_taken = (rs1_data == rs2_data);

            // BNE
            3'b001:
                branch_taken = (rs1_data != rs2_data);

            // BLT
            3'b100:
                branch_taken =
                    ($signed(rs1_data) < $signed(rs2_data));

            // BGE
            3'b101:
                branch_taken =
                    ($signed(rs1_data) >= $signed(rs2_data));

            // BLTU
            3'b110:
                branch_taken =
                    (rs1_data < rs2_data);

            // BGEU
            3'b111:
                branch_taken =
                    (rs1_data >= rs2_data);

            default:
                branch_taken = 1'b0;

        endcase

    end

end

endmodule

//Brach Target Adder
module branch_target_adder(

    input [31:0] pc,
    input [31:0] imm,

    output [31:0] branch_target

);

assign branch_target = pc + imm;

endmodule
