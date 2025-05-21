`include "alu.vh"
`include "cmp.vh"
`include "lsu.vh"
`include "control.vh"

module core(
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] i_instr_data,
    output wire [29:0] o_instr_addr,

    output wire [29:0] o_mem_addr,
    output wire [31:0] o_mem_data,
    output wire        o_mem_we,
    output wire  [3:0] o_mem_mask,
    input  wire [31:0] i_mem_data
);

reg  [29:0] f0_pc;
wire [29:0] f0_pc_inc = f0_pc + 30'd1;
reg  [29:0] f0_pc_next;

wire [31:0] f0_reg1;
wire [31:0] f0_reg2;
reg  [31:0] f0_wb_data;

wire [`ALUOP_WIDTH-1:0] f0_alu_op;
wire              [1:0] f0_alu_sel1;
wire              [1:0] f0_alu_sel2;
reg              [31:0] f0_alu_opnd1;
reg              [31:0] f0_alu_opnd2;
wire             [31:0] f0_alu_res;

wire [`CMPOP_WIDTH-1:0] f0_cmp_op;
wire                    f0_cmp_res;
wire                    f0_is_branch;
wire                    f0_is_jump;
wire              [1:0] f0_wb_sel;
wire                    f0_wb_en;
wire                    f0_is_store;
wire                    f0_is_load;
wire [`LSUOP_WIDTH-1:0] f0_lsu_op;

///////////////////////////////////////////////////////////////////////////////
// Decode instruction.
///////////////////////////////////////////////////////////////////////////////

// Instruction memory has latency=1.
assign o_instr_addr = f0_pc_next;

// Alias to make name shorter.
wire [31:0] f0_ins = i_instr_data;

wire  [4:0] f0_rd   = f0_ins[11:7];
wire  [4:0] f0_rs1  = f0_ins[19:15];
wire  [4:0] f0_rs2  = f0_ins[24:20];
wire [31:0] f0_iimm = {{20{f0_ins[31]}}, f0_ins[31:20]};
wire [31:0] f0_simm = {{20{f0_ins[31]}}, f0_ins[31:25], f0_ins[11:7]};
wire [31:0] f0_bimm = {{19{f0_ins[31]}}, f0_ins[31], f0_ins[7], f0_ins[30:25], f0_ins[11:8], 1'b0};
wire [31:0] f0_uimm = {f0_ins[31:12], {12{1'b0}}};
wire [31:0] f0_jimm = {{11{f0_ins[31]}}, f0_ins[31], f0_ins[19:12], f0_ins[20], f0_ins[30:21], 1'b0};
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Route ALU operands.
///////////////////////////////////////////////////////////////////////////////
always @(*) begin
    case (f0_alu_sel1)
        `ALUSEL1_UIMM: f0_alu_opnd1 = f0_uimm;
        `ALUSEL1_BIMM: f0_alu_opnd1 = f0_bimm;
        `ALUSEL1_JIMM: f0_alu_opnd1 = f0_jimm;
        `ALUSEL1_REG1: f0_alu_opnd1 = f0_reg1;
    endcase
end

always @(*) begin
    case (f0_alu_sel2)
        `ALUSEL2_REG2: f0_alu_opnd2 = f0_reg2;
        `ALUSEL2_IIMM: f0_alu_opnd2 = f0_iimm;
        `ALUSEL2_SIMM: f0_alu_opnd2 = f0_simm;
        `ALUSEL2_PC  : f0_alu_opnd2 = {f0_pc, 2'b0};
    endcase
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Drive PC.
///////////////////////////////////////////////////////////////////////////////
wire f0_is_taken = f0_is_jump || (f0_is_branch && f0_cmp_res);

always @(*) begin
    if (f0_is_taken) begin
        f0_pc_next = f0_alu_res[31:2];
    end
    else begin
        f0_pc_next = f0_pc_inc;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        f0_pc <= 30'b0;
//        stall_satisfied <= 1'b0;
    end
    else begin
        f0_pc <= f0_pc_next;
//        if (is_load) begin
//            stall_satisfied <= !stall_satisfied;
//        end
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Calculate address for LSU.
///////////////////////////////////////////////////////////////////////////////
reg [31:0] f0_lsu_addr;

always @(*) begin
    if (f0_is_load) begin
        f0_lsu_addr = f0_reg1 + f0_iimm;
    end
    else if (f0_is_store) begin
        f0_lsu_addr = f0_reg1 + f0_simm;
    end
    else begin
        f0_lsu_addr = 32'hX;
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// F0 to F1 registers.
///////////////////////////////////////////////////////////////////////////////
reg [31:0] f0f1_uimm;
reg [31:0] f0f1_alu_res;
reg [29:0] f0f1_pc_inc;
reg  [4:0] f0f1_rd;
reg  [1:0] f0f1_wb_sel;
reg        f0f1_wb_en;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        f0f1_uimm    <= 32'h0;
        f0f1_alu_res <= 32'h0;
        f0f1_pc_inc  <= 30'h0;
        f0f1_rd      <= 5'h0;
        f0f1_wb_sel  <= 2'h0;
        f0f1_wb_en   <= 1'h0;
    end
    else begin
        f0f1_uimm    <= f0_uimm;
        f0f1_alu_res <= f0_alu_res;
        f0f1_pc_inc  <= f0_pc_inc;
        f0f1_rd      <= f0_rd;
        f0f1_wb_en   <= f0_wb_en;
        f0f1_wb_sel  <= f0_wb_sel;
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Route writeback.
///////////////////////////////////////////////////////////////////////////////
wire [31:0] f1_lsu_load_data;
reg  [31:0] f1_wb_data;

always @(*) begin
    case (f0f1_wb_sel)
        `WBSEL_UIMM  : f1_wb_data = f0f1_uimm;
        `WBSEL_ALURES: f1_wb_data = f0f1_alu_res;
        `WBSEL_LSU   : f1_wb_data = f1_lsu_load_data;
        `WBSEL_PC_INC: f1_wb_data = {f0f1_pc_inc, 2'b0};
    endcase
end
///////////////////////////////////////////////////////////////////////////////

cmp cmp(
    .i_op  (f0_cmp_op ),
    .i_a   (f0_reg1   ),
    .i_b   (f0_reg2   ),
    .o_res (f0_cmp_res)
);

alu alu(
    .i_op  (f0_alu_op   ),
    .i_a   (f0_alu_opnd1),
    .i_b   (f0_alu_opnd2),
    .o_res (f0_alu_res  )
);

reg_file reg_file(
    .clk        (clk       ),
    .i_rd_addr1 (f0_rs1    ),
    .o_rd_data1 (f0_reg1   ),
    .i_rd_addr2 (f0_rs2    ),
    .o_rd_data2 (f0_reg2   ),
    .i_wr_addr  (f0f1_rd   ),
    .i_wr_data  (f1_wb_data),
    .i_wr_en    (f0f1_wb_en)
);

control control(
    .i_instr      (i_instr_data   ),
    .o_alu_op     (f0_alu_op      ),
    .o_alu_sel1   (f0_alu_sel1    ),
    .o_alu_sel2   (f0_alu_sel2    ),
    .o_cmp_op     (f0_cmp_op      ),
    .o_is_branch  (f0_is_branch   ),
    .o_is_jump    (f0_is_jump     ),
    .o_wb_sel     (f0_wb_sel      ),
    .o_wb_en      (f0_wb_en       ),
    .o_is_store   (f0_is_store    ),
    .o_is_load    (f0_is_load     ),
    .o_lsu_op     (f0_lsu_op      )
);

lsu lsu(
    .clk          (clk             ),
    .rst_n        (rst_n           ),

    .i_is_store   (f0_is_store     ),
    .i_op         (f0_lsu_op       ),
    .i_addr       (f0_lsu_addr     ),
    .i_store_data (f0_reg2         ),
    .o_load_data  (f1_lsu_load_data),

    .o_is_store   (o_mem_we  ),
    .o_addr       (o_mem_addr),
    .o_store_data (o_mem_data),
    .o_store_mask (o_mem_mask),
    .i_load_data  (i_mem_data)
);

endmodule
