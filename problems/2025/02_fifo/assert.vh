`ifndef ASSERT_VH
`define ASSERT_VH

`define assert(condition) if(!(condition)) begin $display("assertion failed"); $finish(1); end

`endif // ASSERT_VH
