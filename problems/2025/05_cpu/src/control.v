`include "alu.vh"
`include "cmp.vh"
`include "control.vh"

module control(
    input  wire             [31:0] i_instr,

    output reg  [`ALUOP_WIDTH-1:0] o_alu_op,
    output reg               [1:0] o_alu_sel1,
    output reg               [1:0] o_alu_sel2,

    output reg  [`CMPOP_WIDTH-1:0] o_cmp_op,
    output reg                     o_is_branch,
    output reg                     o_is_jump,

    output reg               [1:0] o_wb_sel,
    output reg                     o_wb_en,

    output reg                     o_is_store,
    output reg               [3:0] o_store_mask
);

wire [6:0] opcode = i_instr[6:0];
wire [2:0] funct3 = i_instr[14:12];
wire [1:0] funct2 = i_instr[26:25];
wire [4:0] funct5 = i_instr[31:27];

always @(*) begin
    casez ({funct5, funct2, funct3, opcode})
        17'b?????_??_000_0010011: begin // ADDI
            $strobe("%4d S> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                     $time, "ADDI", funct5, funct2, funct3, opcode);

            o_alu_op     = `ALUOP_ADD;
            o_alu_sel1   = `ALUSEL1_REG1;
            o_alu_sel2   = `ALUSEL2_IIMM;
            o_cmp_op     = `CMPOP_X;
            o_is_branch  = 1'b0;
            o_is_jump    = 1'b0;
            o_wb_sel     = `WBSEL_ALURES;
            o_wb_en      = 1'b1;
            o_is_store   = 1'b0;
            o_store_mask = 4'b0000;
        end
    endcase
end

endmodule
