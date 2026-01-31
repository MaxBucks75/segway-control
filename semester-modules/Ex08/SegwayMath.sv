module SegwayMath(
    input  logic signed [11:0] PID_cntrl,
    input  logic        [7:0]  ss_tmr,
    input  logic        [11:0] steer_pot,
    input  logic        en_steer,
    input  logic        pwr_up,
    output logic signed [11:0] lft_spd,
    output logic signed [11:0] rght_spd,
    output logic        too_fast,
    input  logic        clk
);

    // Scale the PID control signal by ss_tmr
    logic signed [19:0] PID_scaled;
    assign PID_scaled = PID_cntrl * $signed({1'b0, ss_tmr});  // 12-bit * 9-bit signed

    logic signed [11:0] PID_ss;  // 11-bit signed to match torque width
    assign PID_ss = PID_scaled / 256;

    // clip steering potentiometer value to 0x200 - 0xE00 (unsigned)
    logic signed [11:0] steer_val;
    logic [11:0] steer_clip;

    // Clip the steer pot signal
    assign steer_clip = (steer_pot > 12'hE00) ? 12'hE00 :
                        (steer_pot < 12'h200) ? 12'h200 :
                        steer_pot;

    assign steer_val = $signed({steer_clip}) - 12'sh7FF; // centered around 0
    logic signed [11:0] steer_scaled;
    assign steer_scaled = (steer_val * 3) >>> 4;  // 3/16 scaling

    // Use PID_ss and steer_val to compute left and right speeds
    logic signed [12:0] lft_torque;
    logic signed [12:0] rght_torque;
    assign lft_torque[12:0] = (en_steer) ? ({PID_ss[11], PID_ss} + {PID_ss[11], PID_ss}) : {PID_ss[11], PID_ss};
    assign rght_torque[12:0] = (en_steer) ? ({PID_ss[11], PID_ss} - {steer_val[11], steer_val}) : {PID_ss[11], PID_ss};

    // Deadzone shaping
    localparam signed MIN_DUTY = 13'h0A8;
    localparam signed LOW_TORQUE_BAND = 7'h2A;
    localparam signed GAIN_MULT = 4'h4;

    // Deadzone shaping for left motor
    logic signed [12:0] lft_shaped;
    logic signed [12:0] rght_shaped;
    logic signed [12:0] lft_torque_comp;
    logic signed [12:0] rght_torque_comp;
    logic signed [16:0] lft_high_gain;
    logic signed [12:0] rght_high_gain;
    logic signed [12:0] lft_torque_abs;
    logic signed [12:0] rght_torque_abs;

    assign lft_torque_comp[12:0] = (lft_torque[12] == 1'b0) ? lft_torque[12:0] + $signed(MIN_DUTY) : lft_torque[12:0] - $signed(MIN_DUTY);
    assign lft_high_gain[16:0] = lft_torque[12:0] * $signed(GAIN_MULT);
    assign lft_torque_abs[12:0] = (lft_torque[12] == 1'b0) ? lft_torque[12:0] : -lft_torque[12:0];
    assign lft_shaped[12:0] = (pwr_up == 1'b0) ? 13'h000 : (lft_torque_abs > $signed(LOW_TORQUE_BAND)) ? lft_torque_comp : lft_high_gain[12:0];

    // Deadzone shaping for right motor
    assign rght_torque_comp[12:0] = (rght_torque[12] == 1'b0) ? (rght_torque + $signed(MIN_DUTY)) : (rght_torque - $signed(MIN_DUTY));
    assign rght_high_gain[12:0] = rght_torque * $signed(GAIN_MULT);
    assign rght_torque_abs[12:0] = (rght_torque[12] == 1'b0) ? rght_torque[12:0] : -rght_torque[12:0];
    assign rght_shaped[12:0] = (pwr_up == 1'b0) ? 13'h000 : (rght_torque > $signed(LOW_TORQUE_BAND)) ? rght_torque_comp : rght_high_gain[12:0];

    // Final saturation and over speed detection
    assign lft_spd =(!lft_shaped[12] && lft_shaped[11]) ? 12'h7FF :
                    (lft_shaped[12] && ~lft_shaped[11]) ? 12'h800 :
                    lft_shaped[11:0];

    assign rght_spd = (!rght_shaped[12] && rght_shaped[11]) ? 12'h7FF :
                      (rght_shaped[12] && ~rght_shaped[11]) ? 12'h800 :
                      rght_shaped[11:0];

    // overspeed threshold: compare against signed 1536 (approx 0x700)
    assign too_fast = (lft_shaped > $signed(12'sd1536)) || (lft_shaped > $signed(12'sd1536)) ? 1'b1 : 1'b0;

endmodule