module PID_Math(
    input logic signed [15:0] ptch,
    input logic signed [15:0] input_rt,
    input logic signed [17:0] integrator,
    output logic signed [11:0] PID_cntrl
);

    logic signed [9:0] pitch_err_sat;
    localparam signed [4:0] P_COEFF = 5'sd9; // coefficient = 9
    logic signed [14:0] P_term;
    logic signed [14:0] I_term;
    logic signed [12:0] D_term;
    logic signed [15:0] P_term_ext;
    logic signed [15:0] I_term_ext;
    logic signed [15:0] D_term_ext;
    logic signed [15:0] PID_sum;

    // Beginning of combination logic
    always_comb begin
        // P-term calculation
        // Saturate pitch error to +/- 512
        if (ptch > 16'sd511)
            pitch_err_sat = 10'sd511;
        else if (ptch < -16'sd512)
            pitch_err_sat = 10'sd512;
        else
            pitch_err_sat = ptch[9:0]; 

        // Multiply pitch error by P_COEFF (9)
        assign P_term = pitch_err_sat * P_COEFF;

        // I-term calculation: divide integrator by 64 (arithmetic shift)
        assign I_term = integrator >>> 6;

        // D-term calculation: divide rate by 64 then negate
        assign D_term = - (input_rt >>> 6);

        // Sign-extend PID terms to 16 bits for summation
        P_term_ext = { {1{P_term[14]}}, P_term };
        I_term_ext = { {1{I_term[14]}}, I_term };
        D_term_ext = { {3{D_term[12]}}, D_term };

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

endmodule