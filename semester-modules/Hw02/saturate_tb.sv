module saturate_tb;

    // Inputs
    reg [16:0] unsigned_err;
    reg signed [16:0] signed_err;
    reg signed [10:0] signed_diff;

    // Outputs
    wire [9:0] unsigned_err_sat;
    wire signed [9:0] signed_err_sat;
    wire signed [6:0] signed_diff_sat;

    // Instantiate DUT
    saturate iDUT (
        .unsigned_err(unsigned_err),
        .unsigned_err_sat(unsigned_err_sat),
        .signed_err(signed_err),
        .signed_err_sat(signed_err_sat),
        .signed_diff(signed_diff),
        .signed_diff_sat(signed_diff_sat)
    );

    initial begin
        
        unsigned_err = 16'h000F;
        if (unsigned_err_sat == 10'h00F) begin
            $display("Test #1 unsigned sat");
            $stop();
        end
        
        unsigned_err = 16'h03FF;
        if (unsigned_err_sat != 10'h3FF) begin
            $display("Test #2 unsigned sat");
            $stop();
        end

        unsigned_err = 16'hFFFF;
        if (unsigned_err_sat != 10'h3FF) begin
            $display("Error #3 unsigned sat");
            $stop();
        end

        signed_err = 16'h8000;
        if (signed_err_sat != 10'h200) begin
            $display("Error #4 signed sat");
            $stop();
        end

        signed_err = 16'h7000;
        if (signed_err_sat != 10'h1FF) begin
            $display("Error #5 signed sat");
            $stop();
        end
        
        signed_err = 16'hFFFF;
        if (signed_err_sat != 10'h1FF) begin
            $display("Error #6 signed sat");
            $stop();
        end
        
        signed_diff = 11'h400;
        if (signed_diff_sat != 7'h40) begin
            $display("Error #7 signed diff sat");
            $stop();
        end

        signed_diff = 11'h3FF;
        if (signed_diff_sat != 7'h3F) begin
            $display("Error #8 signed diff sat");
            $stop();
        end

        signed_diff = 11'h00F;
        if (signed_diff_sat != 7'h0F) begin
            $display("Error #9 signed diff sat");
            $stop();
        end

        $display("All tests passed!");
        $stop();

    end

endmodule
