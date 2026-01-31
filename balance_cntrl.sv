module balance_cntrl #(parameter fast_sim = 1) (
    input  logic                clk,
    input  logic                rst_n,
    input  logic                vld,
    input  logic signed [15:0]  ptch,
    input  logic signed [15:0]  ptch_rt,
    input  logic                pwr_up,
    input  logic                rider_off,
    input  logic       [11:0]   steer_pot,
    input  logic                en_steer,
    output logic signed [11:0]  lft_spd,
    output logic signed [11:0]  rght_spd,
    output logic                too_fast,
    output logic [7:0]          ss_tmr,
    output logic signed [11:0]  PID_cntrl
);

    // Instantiate PID (pass fast_sim parameter down)
    PID #(.fast_sim(fast_sim)) pid_i (
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .ss_tmr(ss_tmr),
        .PID_cntrl(PID_cntrl)
    );

    // Instantiate SegwayMath
    SegwayMath seg_i (
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .pwr_up(pwr_up),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast),
        .clk(clk)
    );

endmodule