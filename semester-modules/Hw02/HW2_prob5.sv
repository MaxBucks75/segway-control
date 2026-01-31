// a) This in an incorrect implementation of a D latch as it isn't level-sensitive.
module latch(d, clk, q);
    input d, clk;
    output reg q;

    // BUG ON NEXT LINE!
    always @(clk) // The block only triggers on clk changes, modeling level-sensitive behavior
        if (clk)
            q <= d;

endmodule



// b) D-FF with an active high synchronous reset

module d_ff_sr (
    input  logic d,
    input  logic clk,
    input  logic rst_n, // active high synchronous reset
    output logic q
);
    always_ff @(posedge clk) begin
        if (rst_n)
            q <= 1'b0; // reset q to 0 when sr is high
        else
            q <= d; // otherwise, capture the value of d
    end
endmodule



// c) D-FF with asynch active low reset and high enable

module d_ff_ae (
    input  logic d,
    input  logic clk,
    input  logic rst_n, // active low asynchronous reset
    input  logic en,    // active high enable
    output logic q
);

    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0; // reset q to 0 when rst_n is low
        else if (en)
            q <= d; // capture the value of d when en is high
        // NO ELSE NEEDED! q will hold its value when en is low
    end
endmodule



// d) SR FF with active high asynch reset and active high synch set.

module sr_ff (
    input  logic s,     // set
    input  logic r,     // reset
    input  logic clk,
    input  logic rst_n, // active low asynchronous reset
    output logic q
);

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            q  <= 1'b0; // reset q to 0 when rst_n is low
        else if (s && !r)
            q  <= 1'b1; // set q to 1 when s is high and r is low
        else if (!s && r)
            q  <= 1'b0; // reset q to 0 when r is high and s is low
        else if (s && r) // r has priority over s
            q <= 1'b0; // reset q to 0 when both s and r are high
        // NO ELSE NEEDED! q will hold its value when s and r are both low
    end
endmodule

// e) Does the use of the always_ff construct ensure the logic will infer a flop?
//
// No, the use of always_ff does not guarantee that the logic will infer a flip-flop.
// The actual behavior depends on the sensitivity list and the assignments within the always_ff block.
// For example, if the sensitivity list does not include a clock edge (e.g., posedge clk),
// or if the assignments are not made in a way that reflects sequential logic, then it may not infer a flip-flop.
// An example of this is always_ff @(clk). With no edge control, this will infer a latch 
// (level-sensitive) instead of a flip-flop (edge-senstive).
