module rst_synch (

    input logic RST_n,
    input logic clk,
    output logic rst_n

);

    logic sync1, sync2;

// Negative-edge triggered synchronizer
    always @(negedge clk, negedge RST_n) begin
        if (!RST_n) begin
            // Asynchronous reset
            sync1 <= 1'b0;
            sync2 <= 1'b0;
        end
        else begin
            // Double flop release
            sync1 <= 1'b1;
            sync2 <= sync1;
        end
    end

    assign rst_n = sync2;

endmodule
