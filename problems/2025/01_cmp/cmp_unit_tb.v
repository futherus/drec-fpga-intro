`timescale 1ns/1ps
`include "cmp_unit.vh"

module cmp_unit_tb;

reg  [`CMPOP_WIDTH-1:0] op;
reg  [31:0] rs1, rs2;
wire taken;
reg  taken_ref;

assign is_ok = (taken == taken_ref);

`define TEST(OP__, RS1__, RS2__, TAKEN_REF__)                                       \
    op = `OP__;                                                                     \
    rs1 = RS1__;                                                                    \
    rs2 = RS2__;                                                                    \
    taken_ref = TAKEN_REF__;                                                        \
    #1;                                                                             \
    $display("[%6t] %s %10d, %10d = %d (ref = %d ? %s)", $realtime, `"OP__`",       \
             RS1__, RS2__, taken, TAKEN_REF__, is_ok ? "OK" : "!!! ERROR !!!");

initial begin
    $dumpvars;
    $display("[%6t] Start", $realtime);

    /**
     * Careful usage of CMPOP_*** define inside macro.
     * Note that CMPOP_*** is used without `
     */

    `TEST( CMPOP_BEQ, 2, 3, 0);
    `TEST( CMPOP_BEQ, 3, 3, 1);
    `TEST( CMPOP_BEQ, 0, 0, 1);

    `TEST( CMPOP_BNE, 2, 3, 1);
    `TEST( CMPOP_BNE, 3, 3, 0);
    `TEST( CMPOP_BNE, 0, 0, 0);

    $display("");

    `TEST( CMPOP_BLT, 2, 3, 1);
    `TEST( CMPOP_BLT, 3, 2, 0);
    `TEST( CMPOP_BLT, 0, 0, 0);
    `TEST( CMPOP_BLT,  33,  22, 0);
    `TEST( CMPOP_BLT,  33, -22, 0);
    `TEST( CMPOP_BLT, -33,  22, 1);
    `TEST( CMPOP_BLT, -33, -22, 1);
    `TEST( CMPOP_BLT,  22,  33, 1);
    `TEST( CMPOP_BLT,  22, -33, 0);
    `TEST( CMPOP_BLT, -22,  33, 1);
    `TEST( CMPOP_BLT, -22, -33, 0);

    $display("");

    `TEST( CMPOP_BLTU, 2, 3, 1);
    `TEST( CMPOP_BLTU, 3, 2, 0);
    `TEST( CMPOP_BLTU, 0, 0, 0);
    `TEST( CMPOP_BLTU,  33,  22, 0);
    `TEST( CMPOP_BLTU,  33, -22, 1);
    `TEST( CMPOP_BLTU, -33,  22, 0);
    `TEST( CMPOP_BLTU, -33, -22, 1);
    `TEST( CMPOP_BLTU,  22,  33, 1);
    `TEST( CMPOP_BLTU,  22, -33, 1);
    `TEST( CMPOP_BLTU, -22,  33, 0);
    `TEST( CMPOP_BLTU, -22, -33, 0);

    $display("");

    `TEST( CMPOP_BGE, 2, 3, 0);
    `TEST( CMPOP_BGE, 3, 2, 1);
    `TEST( CMPOP_BGE, 0, 0, 1);
    `TEST( CMPOP_BGE,  33,  22, 1);
    `TEST( CMPOP_BGE,  33, -22, 1);
    `TEST( CMPOP_BGE, -33,  22, 0);
    `TEST( CMPOP_BGE, -33, -22, 0);
    `TEST( CMPOP_BGE,  22,  33, 0);
    `TEST( CMPOP_BGE,  22, -33, 1);
    `TEST( CMPOP_BGE, -22,  33, 0);
    `TEST( CMPOP_BGE, -22, -33, 1);

    $display("");

    `TEST( CMPOP_BGEU, 2, 3, 0);
    `TEST( CMPOP_BGEU, 3, 2, 1);
    `TEST( CMPOP_BGEU, 0, 0, 1);
    `TEST( CMPOP_BGEU,  33,  22, 1);
    `TEST( CMPOP_BGEU,  33, -22, 0);
    `TEST( CMPOP_BGEU, -33,  22, 1);
    `TEST( CMPOP_BGEU, -33, -22, 0);
    `TEST( CMPOP_BGEU,  22,  33, 0);
    `TEST( CMPOP_BGEU,  22, -33, 0);
    `TEST( CMPOP_BGEU, -22,  33, 1);
    `TEST( CMPOP_BGEU, -22, -33, 1);

    $display("[%6t] Done", $realtime);
    $finish;
end

cmp_unit dut(.op(op), .i_a(rs1), .i_b(rs2), .out(taken));

endmodule
