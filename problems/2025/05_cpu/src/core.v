`include "alu.vh"
`include "cmp.vh"
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

reg  [29:0] pc;
wire [29:0] pc_inc = pc + 30'd1;
wire [29:0] pc_next;

wire [31:0] reg1;
wire [31:0] reg2;
reg  [31:0] reg_wb;

wire [31:0] lsu_load_data;

wire [`ALUOP_WIDTH-1:0] alu_op;
wire              [1:0] alu_sel1;
wire              [1:0] alu_sel2;
reg              [31:0] alu_opnd1;
reg              [31:0] alu_opnd2;
wire             [31:0] alu_res;

wire [`CMPOP_WIDTH-1:0] cmp_op;
wire                    cmp_res;
wire                    is_branch;
wire                    is_jump;
wire              [1:0] wb_sel;
wire                    wb_en;
wire                    is_store;
wire              [3:0] store_mask;

///////////////////////////////////////////////////////////////////////////////
// Decode instruction.
///////////////////////////////////////////////////////////////////////////////
assign o_instr_addr = pc;

// Alias to make name shorter.
wire [31:0] ins = i_instr_data;

wire  [4:0] rd   = ins[11:7];
wire  [4:0] rs1  = ins[19:15];
wire  [4:0] rs2  = ins[24:20];
wire [31:0] iimm = {{20{ins[31]}}, ins[31:20]};
wire [31:0] simm = {{20{ins[31]}}, ins[31:25], ins[11:7]};
wire [31:0] bimm = {{19{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0};
wire [31:0] uimm = {{12{ins[31]}}, ins[31:12]};
wire [31:0] jimm = {{11{ins[31]}}, ins[31], ins[19:12], ins[20], ins[30:21], 1'b0};
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Route ALU operands and result.
///////////////////////////////////////////////////////////////////////////////
always @(*) begin
    case (alu_sel1)
        `ALUSEL1_UIMM: alu_opnd1 = uimm;
        `ALUSEL1_BIMM: alu_opnd1 = bimm;
        `ALUSEL1_JIMM: alu_opnd1 = jimm;
        `ALUSEL1_REG1: alu_opnd1 = reg1;
    endcase
end

always @(*) begin
    case (alu_sel2)
        `ALUSEL2_REG2: alu_opnd2 = reg2;
        `ALUSEL2_IIMM: alu_opnd2 = iimm;
        `ALUSEL2_SIMM: alu_opnd2 = simm;
        `ALUSEL2_PC  : alu_opnd2 = pc;
    endcase
end

always @(*) begin
    case (wb_sel)
        `WBSEL_UIMM  : reg_wb = uimm;
        `WBSEL_ALURES: reg_wb = alu_res;
        `WBSEL_LSU   : reg_wb = lsu_load_data;
        `WBSEL_PC_INC: reg_wb = pc_inc;
    endcase
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Drive PC.
///////////////////////////////////////////////////////////////////////////////
wire is_taken = is_jump || (is_branch && cmp_res);

assign pc_next = is_taken ? alu_res : pc_inc;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc <= 30'b0;
    end
    else begin
        pc <= pc_next;
    end
end
///////////////////////////////////////////////////////////////////////////////

cmp cmp(
    .i_op  (cmp_op ),
    .i_a   (reg1   ),
    .i_b   (reg2   ),
    .o_res (cmp_res)
);

alu alu(
    .i_op  (alu_op   ),
    .i_a   (alu_opnd1),
    .i_b   (alu_opnd2),
    .o_res (alu_res  )
);

reg_file reg_file(
    .clk        (clk   ),
    .i_rd_addr1 (rs1   ),
    .o_rd_data1 (reg1  ),
    .i_rd_addr2 (rs2   ),
    .o_rd_data2 (reg2  ),
    .i_wr_addr  (rd    ),
    .i_wr_data  (reg_wb),
    .i_wr_en    (wb_en )
);

control control(
    .i_instr      (i_instr_data),
    .o_alu_op     (alu_op      ),
    .o_alu_sel1   (alu_sel1    ),
    .o_alu_sel2   (alu_sel2    ),
    .o_cmp_op     (cmp_op      ),
    .o_is_branch  (is_branch   ),
    .o_is_jump    (is_jump     ),
    .o_wb_sel     (wb_sel      ),
    .o_wb_en      (wb_en       ),
    .o_is_store   (is_store    ),
    .o_store_mask (store_mask  )
);

lsu lsu(
    .i_is_store   (is_store     ),
    .i_addr       (alu_res      ),
    .i_store_data (reg2         ),
    .i_store_mask (store_mask   ),
    .o_load_data  (lsu_load_data),

    .o_is_store   (o_mem_we  ),
    .o_addr       (o_mem_addr),
    .o_store_data (o_mem_data),
    .o_store_mask (o_mem_mask),
    .i_load_data  (i_mem_data)
);

endmodule
