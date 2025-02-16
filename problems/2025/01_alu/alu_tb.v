`timescale 1ns/1ps
`include "alu.vh"

module alu_tb;

reg  [`ALUOP_WIDTH-1:0] op;
reg  [31:0] rs1, rs2;
wire [31:0] rd;
reg  [31:0] rd_ref;

assign is_ok = (rd_ref == rd);

`define TEST(OP__, RS1__, RS2__, RD_REF__)                                          \
    op = `OP__;                                                                     \
    rs1 = RS1__;                                                                    \
    rs2 = RS2__;                                                                    \
    rd_ref = RD_REF__;                                                              \
    #1;                                                                             \
    $display("[%6t] %s %10d, %10d = %10d (ref = %10d ? %s)", $realtime, `"OP__`",   \
             RS1__, RS2__, rd, RD_REF__, is_ok ? "OK" : "!!! ERROR !!!");

initial begin
    $dumpvars;
    $display("[%6t] Start", $realtime);

    /**
     * Careful usage of ALUOP_*** define inside macro.
     * Note that ALUOP_*** is used without `
     */

    `TEST( ALUOP_ADD, 2, 3, 5);
    `TEST( ALUOP_ADD, -7, -3, -10);

    `TEST( ALUOP_SUB, 7, 3, 4);
    `TEST( ALUOP_SUB, -132, -31, -101);

    `TEST( ALUOP_SLL, 2, 3, 16);
    `TEST( ALUOP_SLL, 32'hFFFF_FFFF, 4, 32'hFFFF_FFF0);

    `TEST( ALUOP_SRL, 32, 4, 2);
    `TEST( ALUOP_SRL, 32'hFFFF_FFF0, 8, 32'h00FF_FFFF);

    `TEST( ALUOP_SRA, 32, 4, 2);
    `TEST( ALUOP_SRA, 32'hFFFF_FFF0, 8, 32'hFFFF_FFFF);

    $display("");

    `TEST( ALUOP_SLT, 2, 3, 1);
    `TEST( ALUOP_SLT, 3, 2, 0);
    `TEST( ALUOP_SLT, 0, 0, 0);
    `TEST( ALUOP_SLT,  33,  22, 0);
    `TEST( ALUOP_SLT,  33, -22, 0);
    `TEST( ALUOP_SLT, -33,  22, 1);
    `TEST( ALUOP_SLT, -33, -22, 1);
    `TEST( ALUOP_SLT,  22,  33, 1);
    `TEST( ALUOP_SLT,  22, -33, 0);
    `TEST( ALUOP_SLT, -22,  33, 1);
    `TEST( ALUOP_SLT, -22, -33, 0);

    $display("");

    `TEST( ALUOP_SLTU, 2, 3, 1);
    `TEST( ALUOP_SLTU, 3, 2, 0);
    `TEST( ALUOP_SLTU, 0, 0, 0);
    `TEST( ALUOP_SLTU,  33,  22, 0);
    `TEST( ALUOP_SLTU,  33, -22, 1);
    `TEST( ALUOP_SLTU, -33,  22, 0);
    `TEST( ALUOP_SLTU, -33, -22, 1);
    `TEST( ALUOP_SLTU,  22,  33, 1);
    `TEST( ALUOP_SLTU,  22, -33, 1);
    `TEST( ALUOP_SLTU, -22,  33, 0);
    `TEST( ALUOP_SLTU, -22, -33, 0);

    $display("");

    `TEST( ALUOP_XOR, 32'b0101, 32'b1010, 32'b1111);
    `TEST( ALUOP_XOR, 32'b00101, 32'b10101, 32'b10000);

    `TEST( ALUOP_OR, 32'b0101, 32'b1010, 32'b1111);
    `TEST( ALUOP_OR, 32'b00101, 32'b10101, 32'b10101);

    `TEST( ALUOP_AND, 32'b0101, 32'b1010, 32'b0000);
    `TEST( ALUOP_AND, 32'b00101, 32'b10101, 32'b00101);

    $display("[%6t] Done", $realtime);
    $finish;
end

alu dut(.op(op), .rs1(rs1), .rs2(rs2), .rd(rd));

endmodule
