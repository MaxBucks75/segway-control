module saturate (
    input  logic [16:0]         unsigned_err,
    output logic [9:0]          unsigned_err_sat,
    input  logic signed [16:0]  signed_err,
    output logic signed [9:0]   signed_err_sat,
    input  logic signed [10:0]  signed_diff,
    output logic signed [6:0]   signed_diff_sat
);

    // Unsigned saturation: clamp to 10-bit max (0 .. 1023)\
    always_comb begin
        
        // Unsigned saturation: clamp to 10-bit max (0 .. 1023)
        if (unsigned_err > 10'd1023)
            unsigned_err_sat = 10'h3FF;
        else
            unsigned_err_sat = unsigned_err[9:0];

        // Signed saturation: clamp to 10-bit signed range (-512 .. +511)
        if (signed_err > 10'sd511)
            signed_err_sat = 10'sd511;
        else if (signed_err < -10'sd512)
            signed_err_sat = -10'sd512;
        else
            signed_err_sat = signed_err[9:0];

        // Signed difference saturation: clamp to 7-bit signed range (-64 .. +63)
        if (signed_diff > 7'sd63)
            signed_diff_sat = 7'sd63;
        else if (signed_diff < -7'sd64)
            signed_diff_sat = -7'sd64;
        else
            signed_diff_sat = signed_diff[6:0];
            
    end

endmodule