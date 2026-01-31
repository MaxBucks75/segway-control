module rst_synch(
    input logic RST_n,
    input logic clk,
    output logic rst_n
);

    logic sync_0, sync_1;

    // 2-flop synchronizer
    always_ff @(posedge clk, negedge RST_n) begin
        // Asynchronous reset
        if (!RST_n) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= 1'b1;     // First flop
            sync_1 <= sync_0;   // Second flop equal to first flop's previous state
        end
    end

    assign rst_n = sync_1; // Output of the synchronizer

endmodule