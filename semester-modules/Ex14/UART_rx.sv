module UART_rx(
    input logic clk,
    input logic rst_n,
    input logic RX,
    input logic clr_rdy,
    output logic [7:0] rx_data,
    output logic out
);

    // Parameters
    parameter logic [12:0] BAUD_DIV = 13'h1FFF; // match TX default; adjust to clock

    // Synchronize RX to local clock domain to avoid metastability
    logic [1:0] rx_sync;

    // Baud generator
    logic [12:0] baud_cnt;
    logic baud_tick;

    // Receiver state
    logic receiving;
    logic [3:0] bit_idx; // counts 0..8 (0..7 data, 8 = stop)
    logic [7:0] shift_reg;

    // Initialize / synchronize RX input
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync <= 2'b11; // idle line is '1'
        end else begin
            rx_sync <= {rx_sync[0], RX};
        end
    end

    // Baud counter and tick generation (runs while receiving)
    // When a start edge is detected we preload baud_cnt with half-period so
    // the first sample happens near the middle of the start bit.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= '0;
            baud_tick <= 1'b0;
        end else begin
            if (receiving) begin
                if (baud_cnt == BAUD_DIV) begin
                    baud_cnt <= '0;
                    baud_tick <= 1'b1;
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                    baud_tick <= 1'b0;
                end
            end else begin
                baud_cnt <= '0;
                baud_tick <= 1'b0;
            end
        end
    end

    // Main receiver FSM: detect start, sample data bits LSB-first, check stop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            receiving <= 1'b0;
            bit_idx <= '0;
            shift_reg <= '0;
            rx_data <= '0;
            out <= 1'b0;
        end else begin
            // Clear ready when requested
            if (clr_rdy)
                out <= 1'b0;

            if (!receiving) begin
                // detect falling edge = start bit (previous=1 current=0)
                if (rx_sync == 2'b10) begin
                    receiving <= 1'b1;
                    // preload to half period so we sample in middle of start bit
                    baud_cnt <= BAUD_DIV >> 1;
                    bit_idx <= 4'd0;
                    shift_reg <= '0;
                end
            end else begin
                // while receiving, on each baud_tick sample bit
                if (baud_tick) begin
                    if (bit_idx < 4'd8) begin
                        // sample LSB-first: insert sampled bit into MSB and shift
                        shift_reg <= {rx_sync[0], shift_reg[7:1]};
                        bit_idx <= bit_idx + 1'b1;
                    end else begin
                        // sample stop bit
                        if (rx_sync[0] == 1'b1) begin
                            // valid stop bit -> present received byte
                            rx_data <= shift_reg;
                            out <= 1'b1; // data ready
                        end
                        // either way, go back to idle waiting for next start
                        receiving <= 1'b0;
                        bit_idx <= '0;
                    end
                end
            end
        end
    end

endmodule
