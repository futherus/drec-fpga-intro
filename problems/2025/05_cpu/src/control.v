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
        `define OP(OPER__, ENCODING__, ALUOP__, ALU1__, ALU2__, WBSEL__, WB__, CMPOP__, IS_BRANCH__, IS_JUMP__, IS_STORE__, STORE_MASK__)   \
            ENCODING__: begin                                                                                                               \
                $strobe("%4d S> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",                                                   \
                        $time, `"OPER__`", funct5, funct2, funct3, opcode);                                                                 \
                                                                                                                                            \
                o_alu_op     = ALUOP__;                                                                                                     \
                o_alu_sel1   = ALU1__;                                                                                                      \
                o_alu_sel2   = ALU2__;                                                                                                      \
                o_wb_sel     = WBSEL__;                                                                                                     \
                o_wb_en      = WB__;                                                                                                        \
                o_cmp_op     = CMPOP__;                                                                                                     \
                o_is_branch  = IS_BRANCH__;                                                                                                 \
                o_is_jump    = IS_JUMP__;                                                                                                   \
                o_is_store   = IS_STORE__;                                                                                                  \
                o_store_mask = STORE_MASK__;                                                                                                \
            end

        `include "instrs.mac.vh"

        `undef OP

    default: begin
        $display("%4d D> ILLEGAL INSTRUCTION, funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                 $time, funct5, funct2, funct3, opcode);
        $finish;
    end
    endcase
end

endmodule
