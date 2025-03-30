module fp16mul (
    input  wire [15:0] i_a,
    input  wire [15:0] i_b,
    output wire [15:0] o_res
);

localparam E_BIAS = 15;

// Normal: E!=0             => (-1)^S * (1+M) * 2^(E-B)
// Subnormal: E=0, M!=0     => (-1)^S * M
// Zero: {S=+/-, E=0, M=0}
// +-inf = {S=+/-, E=1..1, M=0}
// NaN   = {S=+/-, E=1..1, M!=0}
//
// FTZ(for res) + DAZ(for args): E=0, M!=0 => E=0, M=0

wire       a_s = i_a[15];
wire [4:0] a_e = i_a[14:10];
wire [9:0] a_m = (a_e == 5'd0) ? 10'd0 : i_a[9:0]; // Perform DAZ.
wire       b_s = i_b[15];
wire [4:0] b_e = i_b[14:10];
wire [9:0] b_m = (b_e == 5'd0) ? 10'd0 : i_b[9:0]; // Perform DAZ.

// 0) Result sign.
wire      res_s = a_s ^ b_s;
reg [4:0] res_e;
reg [9:0] res_m;
assign o_res = {res_s, res_e, res_m};

// 1) Add exponents, multiply mantissas.
wire [21:0] m_mul = {1'b1, a_m} * {1'b1, b_m};
wire  [5:0] e_add = a_e + b_e - E_BIAS;

// 2) Normalize if mantissa in (4, 2].
wire need_normalize = m_mul[21];
wire [20:0] m_norm = (need_normalize) ? m_mul[21:1] : m_mul[20:0];
wire  [5:0] e_norm = (need_normalize) ? e_add + 6'd1 : e_add;

// 3) RoundTiesToEven.
reg [9:0] m_round;
reg [4:0] e_round;
always @(*) begin
    if (is_round_up) begin
        m_round = m_norm[19:10] + 10'd1;
        if (m_round == 10'd0) begin
            // Mantissa overflowed, increment exponent.
            e_round = e_norm[4:0] + 5'd1;
            // if (res_e == 5'b11111) we obtain {S, 1...1, 0} = +-inf, as it should be.
        end
        else begin
            e_round = e_norm[4:0];
        end
    end
    else begin
        m_round = m_norm[19:10];
        e_round = e_norm[4:0];
    end
end

// 4) Handle special cases and obtain final result.
// a=NaN || b=NaN    => res = NaN
// a=inf && b=0      => res = NaN
// a=inf && b=inf    => res = inf
// a=inf && b=normal => res = inf
// a=0   && b=normal => res = 0
always @(*) begin
    if (a_e == 5'b11111 || b_e == 5'b11111) begin
        if (a_m != 10'd0 || b_m != 10'd0) begin
            // One of opnds is NaN => NaN.
            res_m = 10'h77;
            res_e = 5'b11111;
        end
        else if (a_e == 5'd0 || b_e == 5'd0) begin
            // One opnd is inf, another is zero (DAZ) => NaN.
            res_m = 10'h77;
            res_e = 5'b11111;
        end
        else begin
            // One opnd is inf, another is normal/inf.
            res_m = 10'd0;
            res_e = 5'b11111;
        end
    end
    else if (a_e == 5'd0 || b_e == 5'd0) begin
        // One opnd is zero (DAZ).
        res_m = 10'd0;
        res_e = 5'd0;
    end
    else begin
        // Both opnds are normal.
        res_m = (e_round == 5'd0) ? 10'd0 : m_round; // FTZ.
        res_e = e_round;
    end
end

// RoundTiesToEven details.
wire guard_bit = m_norm[9];
wire round_bit = m_norm[8];
// If need_normalize == 1, LSB of m_mul is dropped, therefore we OR it in sticky_bit.
wire sticky_bit = (|m_norm[7:0]) | m_mul[0];

reg is_round_up;
always @(*) begin
    // RoundTiesToEven scheme.
    casez ({guard_bit, round_bit, sticky_bit})
        3'b0??: begin
            is_round_up = 1'b0;
        end
        3'b100: begin
            // Tie: round up if bit-before-guard is 1, round down otherwise.
            is_round_up = m_norm[10];
        end
        3'b101,
        3'b110,
        3'b111: begin
            is_round_up = 1'b1;
        end
    endcase
end

endmodule
