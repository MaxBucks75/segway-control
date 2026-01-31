module arith_tb();

reg [7:0] in_a, in_b;
reg c_in;

wire [7:0] sum;
wire overflow;

arith DUT(.A(in_a), .B(in_b), .SUB(c_in), .SUM(sum), .OV(overflow));

initial begin
    
    $monitor("A=%d B=%d C_in=%b SUM=%d OV=%b", in_a, in_b, c_in, sum, overflow);
    
    // Test addition
    in_a = 8'd50; in_b = 8'd25; c_in = 1'b0; // 50 + 25 = 75 
    #10;
    if (sum !== 8'd75 || overflow !== 1'b0) begin
        $display("Test failed for 50 + 25");
        $stop;
    end
    in_a = 8'd100; in_b = 8'd50; c_in = 1'b0; // 100 + 50 = 150 
    #10;
    if (sum !== 8'd150 || overflow !== 1'b1) begin
        $display("Test failed for 100 + 50");
        $stop;
    end
    in_a = 8'd127; in_b = 8'd1; c_in = 1'b0; // Overflow case: 127 + 1 
    #10;
    if (sum !== -8'd128 || overflow !== 1'b1) begin
        $display("Test failed for 127 + 1");
        $stop;
    end

    // Test subtraction
    in_a = 8'd50; in_b = 8'd25;// 50 - 25 = 25 
    c_in = 1'b1; #10;
    if (sum !== 8'd25 || overflow !== 1'b0) begin
        $display("Test failed for 50 - 25");
        $stop;
    end
    in_a = 8'd25; in_b = 8'd50; c_in = 1'b1; // Underflow case: 25 - 50 
    #10;
    if (sum !== -8'd25 || overflow !== 1'b0) begin
        $display("Test failed for 25 - 50");
        $stop;
    end
    in_a = -8'd100; in_b = -8'd30; c_in = 1'b1; // -100 - (-30) = -70
    #10;
    if (sum !== -8'd70 || overflow !== 1'b0) begin
        $display("Test failed for -100 - (-30)");
        $stop;
    end

    // Edge cases
    in_a = -8'd128; in_b = -8'd1; c_in = 1'b0; #10; // Overflow case: -128 + (-1)
    if (sum !== 8'd127 || overflow !== 1'b1) begin
        $display("Test failed for -128 + (-1)");
        $stop;
    end
    in_a = -8'd128; in_b = -8'd1; c_in = 1'b1; #10; // -128 - (-1) = -127
    if (sum !== -8'd127 || overflow !== 1'b0) begin
        $display("Test failed for -128 - (-1)");
        $stop;
    end

    // Test overflow logic
    in_a = 8'h80; in_b = 8'h40; c_in = 1'b1; // Overflow case: -128 - 64
    #10;
    if (sum !== 8'h7C || overflow !== 1'b1) begin
        $display("Test failed for -128 - 64");
        $stop;
    end

    $display("All tests passed!");
    $stop;

end

endmodule