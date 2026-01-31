module four_bit_addr(
    input logic [3:0] A,
    input logic [3:0] B,
    input logic Cin,
    output logic [3:0] Sum,
    output logic Co
);

    // Register containing the sum and carry value
    logic [4:0] raw_sum;

    assign raw_sum = A + B + Cin;
    assign Sum = raw_sum[3:0];
    assign Co = raw_sum[4];

endmodule