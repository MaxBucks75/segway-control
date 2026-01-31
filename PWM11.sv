module PWM11(
    input logic clk,
    input logic rst_n,
    input logic [10:0] duty,
    output logic PWM1,
    output logic PWM2,
    output logic PWM_synch,
    output logic ovr_I_blank
);

    localparam NONOVERLAP = 11'h040; // Buffer ensuring PWM1 and PWM2 are never both high (would result in short)
    logic [10:0] cnt;
    logic pwm1_set, pwm1_rst, pwm2_set, pwm2_rst;

    assign PWM_synch = ~|cnt; // PWM_synch is high when cnt is zero, for one pulse
    assign ovr_I_blank = ((NONOVERLAP < cnt) && (cnt < (NONOVERLAP+128))) | ( ((NONOVERLAP+duty) < cnt) && (cnt < (NONOVERLAP+duty+128)) ) ? 1'b1 : 1'b0;

    // Accumulators
    logic [12:0] add_ext;
    logic [10:0] add_sat;

    // set/reset comb logic
    assign add_ext = duty + NONOVERLAP;
    assign add_sat = (add_ext > 11'h7FF) ? 11'h7FF : add_ext[10:0];
    assign pwm1_set = (cnt >= NONOVERLAP);      // PWM1 is high from NONOVERLAP to duty
    assign pwm1_rst = (cnt >= duty);
    assign pwm2_set = (cnt >= add_sat);         // PWM2 is high from duty + NONOVERLAP to 2047
    assign pwm2_rst = (&cnt);

    // PWM 1 ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            PWM1 <= 1'b0;
        else begin
            if (pwm1_rst)
                PWM1 <= 1'b0;
            else if (pwm1_set)
                PWM1 <= 1'b1;
        end
    end

    // PWM 2 ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            PWM2 <= 1'b0;
        else begin
            if (pwm2_rst)
                PWM2 <= 1'b0;
            else if (pwm2_set)
                PWM2 <= 1'b1;
        end
    end

    // counter ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            cnt <= '0;
        else if (cnt != 11'h7FF)
            cnt <= cnt + 1'b1;
        else
            cnt <= '0;
    end

endmodule