module PWM11_tb;

    // DUT signals
    logic clk;
    logic rst_n;
    logic [10:0] duty;
    logic pwm1;
    logic pwm2;
    wire PWM_synch;
    wire ovr_I_blank;

    PWM11 dut (
        .clk(clk),
        .rst_n(rst_n),
        .duty(duty),
        .pwm1(pwm1),
        .pwm2(pwm2),
        .PWM_synch(PWM_synch),
        .ovr_I_blank(ovr_I_blank)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Monitor for console output
    initial begin
        $display("time\tduty\tpwm1\tpwm2\tPWM_synch\tovr_I_blank");
        $monitor("%0t\t%0h\t%b\t%b\t%b\t%b", $time, duty, pwm1, pwm2, PWM_synch, ovr_I_blank);
    end

    always @(posedge clk) begin
        if (pwm1 && pwm2) begin
            $display("[%0t] ERROR: pwm1 and pwm2 are both high!", $time);
            $stop();
        end
    end

    initial begin

        // Reset
        rst_n = 1'b0;
        duty = 11'h000;
        #20;
        rst_n = 1'b1;

        @(posedge PWM_synch);

        // Test values: 0, small, just below NONOVERLAP, equal NONOVERLAP, mid, max
        duty = 11'h000; // 0% (expect pwm1=0 pwm2 toggles)
        @(posedge PWM_synch); repeat (4) @(posedge PWM_synch);

        duty = 11'h020; // small duty
        @(posedge PWM_synch); repeat (4) @(posedge PWM_synch);

        duty = 11'h03F; // just below NONOVERLAP
        @(posedge PWM_synch); repeat (4) @(posedge PWM_synch);

        duty = 11'h040; // equal NONOVERLAP
        @(posedge PWM_synch); repeat (4) @(posedge PWM_synch);

        duty = 11'h200; // mid duty
        @(posedge PWM_synch); repeat (4) @(posedge PWM_synch);

        duty = 11'h7FF; // full-scale
        @(posedge PWM_synch); repeat (4) @(posedge PWM_synch);

        $display("Yahoo! The code simulated without breaking");
        #10 $stop();
        
    end

endmodule
