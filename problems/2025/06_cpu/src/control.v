`include "alu.vh"
`include "cmp.vh"
`include "lsu.vh"
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
    output reg                     o_is_load,
    output reg  [`LSUOP_WIDTH-1:0] o_lsu_op
);

wire [6:0] opcode = i_instr[6:0];
wire [2:0] funct3 = i_instr[14:12];
wire [1:0] funct2 = i_instr[26:25];
wire [4:0] funct5 = i_instr[31:27];

always @(*) begin
    casez ({funct5, funct2, funct3, opcode})
        `define OP(OPER__, ENCODING__, ALUOP__, ALU1__, ALU2__, WBSEL__, WB__, CMPOP__, LSUOP__, TYPE__) \
            ENCODING__: begin                                                                            \
                // $strobe("%4d S> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",                \
                //        $time, OPER__, funct5, funct2, funct3, opcode);                                  \
                                                                                                         \
                o_alu_op     = ALUOP__;                                                                  \
                o_alu_sel1   = ALU1__;                                                                   \
                o_alu_sel2   = ALU2__;                                                                   \
                o_wb_sel     = WBSEL__;                                                                  \
                o_wb_en      = WB__;                                                                     \
                o_cmp_op     = CMPOP__;                                                                  \
                o_lsu_op     = LSUOP__;                                                                  \
                o_is_branch  = TYPE__ == `OPTYPE_BRANCH;                                                 \
                o_is_jump    = TYPE__ == `OPTYPE_JUMP;                                                   \
                o_is_store   = TYPE__ == `OPTYPE_STORE;                                                  \
                o_is_load    = TYPE__ == `OPTYPE_LOAD;                                                   \
            end

        `include "instrs.mac.vh"

        `undef OP

    default: begin
        $display("%4d D> ILLEGAL INSTRUCTION, funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                 $time, funct5, funct2, funct3, opcode);

        o_alu_op     = `ALUOP_WIDTH'dX;
        o_alu_sel1   = 2'dX;
        o_alu_sel2   = 2'dX;
        o_wb_sel     = 2'dX;
        o_wb_en      = 1'b0;
        o_cmp_op     = `CMPOP_WIDTH'dX;
        o_lsu_op     = `LSUOP_WIDTH'dX;
        o_is_branch  = 1'b0;
        o_is_jump    = 1'b0;
        o_is_store   = 1'b0;
        o_is_load    = 1'b0;
    end
    endcase
end

endmodule
