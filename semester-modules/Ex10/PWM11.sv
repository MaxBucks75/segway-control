module PWM11(
    input logic clk,
    input logic rst_n,
    input logic [10:0] duty,
    output logic pwm1,
    output logic pwm2,
    output logic PWM_synch,
    output logic ovr_I_blank
);

    localparam int NONOVERLAP = 11'h040; // Buffer ensuring PWM1 and PWM2 are never both high (would result in short)
    logic [10:0] cnt;
    logic pwm1_set, pwm1_rst, pwm2_set, pwm2_rst;

    // counter ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n)
            cnt <= 11'h000;
        else if (cnt != 11'h7FF)
            cnt <= cnt + 1;
        else
            cnt <= 0;
    end

    // set/reset comb logic
    always_comb begin
        pwm1_set = (cnt >= (duty + NONOVERLAP)); // PWM1 is high from NONOVERLAP to duty
        pwm1_rst = &cnt;
        pwm2_set = (cnt >= (NONOVERLAP));        // PWM2 is high from duty + NONOVERLAP to 2047
        pwm2_rst = (cnt >= duty);
    end

    // PWM 1 ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n)
            pwm1 <= 1'b0;
        else if (pwm1_set)
            pwm1 <= 1'b1;
        else if (pwm1_rst)
            pwm1 <= 1'b0;
    end

    // PWM 2 ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n)
            pwm2 <= 1'b0;
        else if (pwm2_set)
            pwm2 <= 1'b1;
        else if (pwm2_rst)
            pwm2 <= 1'b0;
    end

    // Additional comb logic 
    always_comb begin

        PWM_synch = ~|cnt; // Will be used in the future to ensure duty doesn't change in the middle of PWM cycle

        // If the current is too high, another module can use this signal to shutdown the circuit
        ovr_I_blank = (NONOVERLAP < cnt < (NONOVERLAP + 128)) || ((NONOVERLAP + duty) < cnt < (NONOVERLAP + duty + 128));

    end

endmodule