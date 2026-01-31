module SegwayMath_tb();

    // Inputs
    logic signed [11:0] PID_cntrl;
    logic [7:0] ss_tmr;
    logic [11:0] steer_pot;
    logic en_steer; 
    logic pwr_up;   

    // Outputs
    logic signed [11:0] lft_spd;
    logic signed [11:0] rght_spd;
    logic too_fast;

    logic clk;

    // Instantiate DUT
    SegwayMath iDUT (
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

    initial begin
        // Initialize Inputs per user request
        PID_cntrl = 12'h5FF; // start value (will ramp toward 12'hE00)
        ss_tmr    = 8'h00;   // start at 0 (will ramp toward 8'hFF)
        steer_pot = 12'h7FF; // Neutral position
        en_steer  = 1'b0;    // steer_en = 0
        pwr_up    = 1'b1;    // pwr_up = 1

        clk = 1'b0;
    end

always @(posedge clk) begin
    if (ss_tmr != 8'hFF) begin
        // Clamp instead of wrapping
        if (ss_tmr >= 8'hF7)
            ss_tmr <= 8'hFF;
        else
            ss_tmr <= ss_tmr + 8'd8;

    end else if (PID_cntrl > -12'sd512) begin
        if (PID_cntrl - 12'sd16 <= -12'sd512)
            PID_cntrl <= -12'sd512;
        else
            PID_cntrl <= PID_cntrl - 12'sd16;

    end else begin
        $stop();
    end
end

    always #5 clk = ~clk;

endmodule