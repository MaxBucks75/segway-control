module PID(
    input  logic signed [15:0] ptch,
    input  logic signed [15:0] ptch_rt,
    input  logic clk,
    input  logic rst_n,
    input  logic vld,
    input  logic pwr_up,
    input  logic rider_off,
    output logic [7:0] ss_tmr,
    output logic signed [11:0] PID_cntrl
);

    // Internal signals
    logic signed [9:0]  pitch_err_sat;
    localparam signed [4:0] P_COEFF = 5'sd9; // coefficient = 9
    logic signed [14:0] P_term;
    logic signed [11:0] I_term;
    logic signed [12:0] D_term;
    logic signed [15:0] P_term_ext;
    logic signed [15:0] I_term_ext;
    logic signed [15:0] D_term_ext;
    logic signed [15:0] PID_sum;

    // Internal accumulator logic for integrator
    logic signed [17:0] pitch_err_sat_ext;
    logic signed [17:0] integrator_sum;     // accumulator register for the integrator term 
    logic signed [18:0] integrator_next;    // accumulator for overflow detection on integrator term 

    // Softstart timer
    logic [26:0] long_tmr;

    // Beginning of combination logic
    always_comb begin
        // P-term calculation
        // Saturate pitch error to +/- 512
        if (ptch > 16'sd511)
            pitch_err_sat = 10'sd511;
        else if (ptch < -16'sd512)
            pitch_err_sat = -10'sd512;
        else
            pitch_err_sat = ptch[9:0]; 

        // Multiply pitch error by P_COEFF (9)
        P_term = pitch_err_sat * P_COEFF;

        // Extend pitch_err_sat for use in the integrator
        pitch_err_sat_ext = {{8{pitch_err_sat[9]}}, pitch_err_sat};

        // Use the last 12 bits of the accumulator as the I-term
        I_term = integrator_sum[17:6];

        // D-term calculation: divide rate by 64 then negate
        D_term = - (ptch_rt >>> 6);

        // Sign-extend PID terms to 16 bits for summation
        P_term_ext = {{1{P_term[14]}}, P_term};
        I_term_ext = {{4{I_term[11]}}, I_term};
        D_term_ext = {{3{D_term[12]}}, D_term};

        // Sum PID terms
        PID_sum = P_term_ext + I_term_ext + D_term_ext;

        // Saturate PID_sum to +/- 2048 to get final 12-bit PID_cntrl output
        if (PID_sum > 16'sd2047)
            PID_cntrl = 12'sd2047;
        else if (PID_sum < -16'sd2048)
            PID_cntrl = -12'sd2048;
        else
            PID_cntrl = PID_sum[11:0];
    end

    // Integrator accumulator logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (rider_off || !rst_n)
            integrator_sum <= '0;
        else if (vld) begin
            // Calculate the next integration and if there is overflow, clamp the result
            integrator_next = integrator_sum + pitch_err_sat_ext;
            if (integrator_next > $signed(18'h1FFFF))
                integrator_sum <= $signed(18'h1FFFF); // maximum 18-bit positive signed #
            else if (integrator_next < $signed(18'h20000))
                integrator_sum <= $signed(18'h20000); // minimum 18-bit positive signed #
            else
                // If there is no overflow assign as per usual
                integrator_sum <= integrator_sum + pitch_err_sat_ext;
        end

    end

    // Softstart timer logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || !pwr_up)
            long_tmr <= '0; // zero bits
        else if (!(long_tmr[26:19] & 8'hFF))
            long_tmr <= long_tmr + 1'b1; // increment timer
    end

    // Softstart timer output
    assign ss_tmr = long_tmr[26:19];

endmodule
