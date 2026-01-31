module PB_release(
    input logic clk,
    input logic rst_n,
    input logic PB,
    output logic released
);

    logic q_ff1, q_ff2, q_ff3;  // Q outputs of FF1, FF2, and FF3
    logic d_ff2, d_ff3; // D inputs to FF2 and FF3 

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            q_ff1 <= 1'b0;
            q_ff2 <= 1'b0;
            q_ff3 <= 1'b0;
        end else begin
            q_ff1 <= PB;       // First flip-flop captures the raw button input
            q_ff2 <= d_ff2;    // Second flip-flop captures the output of the first flip-flop
            q_ff3 <= d_ff3;    // Third flip-flop captures the output of the second flip-flop
        end
    end

    always_comb begin
        d_ff2 = q_ff1; // D input to FF2 is the Q output of FF1
        d_ff3 = q_ff2; // D input to FF3 is the Q output of FF2
    end

    assign released = (d_ff3 == 1'b1 && q_ff3 == 1'b0) ? 1'b1 : 1'b0; // Output high after ff3 detects rising edge



endmodule