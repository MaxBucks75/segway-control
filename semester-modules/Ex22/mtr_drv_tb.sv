module mtr_dr_tb();

    logic clk, rst_n;
    logic lft_spd;
    logic rght_spd;
    logic OVR_I_lft;
    logic OVR_I_rght;
    logic PWM1_lft;
    logic PWM2_lft;
    logic PWM1_rght;
    logic PWM2_rght;
    logic OVR_I_shtdwn;

    mtr_drv iDUT(
        .clk(clk),
        .rst_n(rst_n),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .OVR_I_lft(OVR_I_lft),
        .OVR_I_rght(OVR_I_rght),
        .PWM1_lft(PWM1_lft),
        .PWM2_lft(PWM2_lft),
        .PWM1_rght(PWM1_rght),
        .PWM2_rght(PWM2_rght),
        .OVR_I_shtdwn(OVR_I_shtdwn)
    );

    int num_pwm_sync_pulses;

    always #5 clk = ~clk;

    initial begin
        
        // Initialize and reset signals
        clk = 1'b0;
        rst_n = 1'b0;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        OVR_I_lft = 1'b1;
        num_pwm_sync_pulses = 0;

        // Test the first 40 PWM_sync assertions of OVR current shutdown after reset
        while (num_pwm_sync_pulses < 40) begin

            @(posedge clk);

            if (OVR_I_shtdwn === 1'b1) begin
                $display("ERROR: Over current shutdown was asserted withing blanking window");
                $stop();
            end

            // increment index on PWM_sync pulse
            if (iDUT.PWM_sync === 1'b1) begin
                num_pwm_sync_pulses = num_pwm_sync_pulses + 1;
            end

        end

        // Now outside blanking window

        num_pwm_sync_pulses = 0; // Reset number of pulses counter

        while (num_pwm_sync_pulses < 40) begin

            @(posedge clk);

            if (OVR_I_shtdwn === 1'b1) begin
                $display("YAHOO! Over current shutdown was asserted outside the blanking window");
                $stop();
            end

            // increment index on PWM_sync pulse
            if (iDUT.PWM_sync === 1'b1) begin
                num_pwm_sync_pulses = num_pwm_sync_pulses + 1;
            end

        end

        $display("ERROR: Over current shutdown wasn't asserted outside the blanking window");
        $stop();

    end

endmodule