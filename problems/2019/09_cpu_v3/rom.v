module rom #(parameter ADDR_WIDTH = 5, parameter WIDTH = 32)(
    input [ADDR_WIDTH - 1:0]addr,
    input clk,

    output reg [WIDTH - 1:0]q
);

initial begin
    q = 0;
end

localparam MEMORY_WORDS = 2**ADDR_WIDTH;
reg [WIDTH - 1:0]mem[2**ADDR_WIDTH - 1:0];

initial begin
    $readmemh("samples/fib_riscv.txt", mem, 0, MEMORY_WORDS - 1);
end

always @(posedge clk) begin
    q <= mem[addr];
end

endmodule
