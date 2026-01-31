module up_dwn_cnt4(
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic dwn,
    output logic [3:0] cnt
);

    // 4-bit up/down counter with enable and asynchronous reset
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'b0000; // Asynchronous reset to 0
        else if (en) begin
            if (dwn) begin
                if (cnt != 4'b0000)
                    cnt <= cnt - 1; // Count down
            end else begin
                if (cnt != 4'b1111)
                    cnt <= cnt + 1; // Count up
            end
        end
    end

endmodule