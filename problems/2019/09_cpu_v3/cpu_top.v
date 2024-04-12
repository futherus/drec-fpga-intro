module cpu_top(
    input clk,

    output [15:0]data_out
);

localparam ADDR_WIDTH = 5;

wire [31:0]instr_addr;
wire [31:0]instr_data;
wire [31:0]word_addr = instr_addr >> 2;
rom #(
    .ADDR_WIDTH(ADDR_WIDTH)
) rom(
    .clk(clk),
    .addr(word_addr[ADDR_WIDTH-1:0]),
    .q(instr_data)
);

wire [31:0]mem_addr;
wire [31:0]mem_data;
wire mem_we;
mem_ctrl mem_ctrl(
    .clk(clk), .addr(mem_addr), .data(mem_data),
    .we(mem_we), .data_out(data_out)
);

always @* begin
    $display("%4d D> data_out: %h", $time, data_out);
end

core core(
    .clk(clk),
    .instr_data(instr_data), .last_pc(31),
    .instr_addr(instr_addr),
    .mem_addr(mem_addr), .mem_data(mem_data),
    .mem_we(mem_we)
);

endmodule
