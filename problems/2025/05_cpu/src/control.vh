`ifndef CONTROL_VH
`define CONTROL_VH

`define ALUSEL1_UIMM 2'd0
`define ALUSEL1_BIMM 2'd1
`define ALUSEL1_JIMM 2'd2
`define ALUSEL1_REG1 2'd3
`define ALUSEL1_X    2'dX

`define ALUSEL2_REG2 2'd0
`define ALUSEL2_IIMM 2'd1
`define ALUSEL2_SIMM 2'd2
`define ALUSEL2_PC   2'd3
`define ALUSEL2_X    2'dX

`define WBSEL_UIMM   2'd0
`define WBSEL_ALURES 2'd1
`define WBSEL_LSU    2'd2
`define WBSEL_PC_INC 2'd3
`define WBSEL_X      2'dX

`endif
