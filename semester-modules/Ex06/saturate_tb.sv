Timara Empower Recovery
Number: 608-571-3866





module saturate_tb;

    // Inputs
    reg [16:0] unsigned_err;
    reg signed [16:0] signed_err;
    reg signed [10:0] signed_diff;

    // Outputs
    wire [9:0] unsigned_err_sat;
    wire signed [9:0] signed_err_sat;
    wire signed [6:0] signed_diff_sat;

    // loop variable declared at module scope to satisfy older tools that require declarations before statements
    integer i;

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
        $display("Starting saturate testbench");
        $dumpfile("saturate_tb.vcd");
        $dumpvars(0, saturate_tb);

        // Test vectors: (value, description)
        // Unsigned: 0, small, max in range, just above max
        unsigned_err = 17'd0; signed_err = 17'sd0; signed_diff = 11'sd0; #5;
        $display("u=%0d -> sat=%0d | s=%0d -> sat=%0d | d=%0d -> sat=%0d", unsigned_err, unsigned_err_sat, signed_err, signed_err_sat, signed_diff, signed_diff_sat);

        unsigned_err = 17'd100; signed_err = 17'sd100; signed_diff = 11'sd50; #5;
        $display("u=%0d -> sat=%0d | s=%0d -> sat=%0d | d=%0d -> sat=%0d", unsigned_err, unsigned_err_sat, signed_err, signed_err_sat, signed_diff, signed_diff_sat);

        unsigned_err = 17'd1023; signed_err = 17'sd511; signed_diff = 11'sd63; #5; // at positive limits
        $display("u=%0d -> sat=%0d | s=%0d -> sat=%0d | d=%0d -> sat=%0d", unsigned_err, unsigned_err_sat, signed_err, signed_err_sat, signed_diff, signed_diff_sat);

        unsigned_err = 17'd1024; signed_err = 17'sd512; signed_diff = 11'sd64; #5; // just above positive limits
        $display("u=%0d -> sat=%0d | s=%0d -> sat=%0d | d=%0d -> sat=%0d", unsigned_err, unsigned_err_sat, signed_err, signed_err_sat, signed_diff, signed_diff_sat);

        unsigned_err = 17'd65535; signed_err = -17'sd512; signed_diff = -11'sd64; #5; // large unsigned, at negative signed limits
        $display("u=%0d -> sat=%0d | s=%0d -> sat=%0d | d=%0d -> sat=%0d", unsigned_err, unsigned_err_sat, signed_err, signed_err_sat, signed_diff, signed_diff_sat);

        unsigned_err = 17'd65535; signed_err = -17'sd600; signed_diff = -11'sd100; #5; // below negative limits
        $display("u=%0d -> sat=%0d | s=%0d -> sat=%0d | d=%0d -> sat=%0d", unsigned_err, unsigned_err_sat, signed_err, signed_err_sat, signed_diff, signed_diff_sat);

        // random sweeps quick check
        for (i = -600; i <= 600; i = i + 200) begin
            signed_err = i; signed_diff = i; unsigned_err = i >= 0 ? i : 0; #2;
            $display("s=%0d -> sat=%0d | d=%0d -> sat=%0d", signed_err, signed_err_sat, signed_diff, signed_diff_sat);
        end

        $display("Testbench finished");
        #5 $stop;
    end

endmodule
