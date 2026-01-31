module UART_rx(
    input logic clk,
    input logic rst_n,
    input logic RX,
    input logic clr_rdy,
    output logic [7:0] rx_data,
    output logic rdy
);

    logic [1:0] rx_sync;    // Signal for synching the data coming in, avoiding metastability
    logic [12:0] baud_cnt;
    logic baud_tick;
    logic receiving;
    logic [3:0] bit_cnt;
    logic [7:0] shift_reg;

    // Double-flop the rx line to avoid metastability
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            rx_sync <= 2'b11; // idle line is '1'

        end else begin
            rx_sync <= {rx_sync[0], RX};
        end
    end

    // Baud counter control
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            baud_cnt <= '0;
            baud_tick <= 1'b0;
        end else begin

            // Increment the baud counter if we are receiving data
            // When generating the receiving signal, we will preload half
            // of the baud_cnt, that way when we sample it's in the middle
            // of the data signal
            if (receiving) begin
                if (baud_cnt == 13'h1FFF) begin
                    baud_cnt <= '0;
                    baud_tick <= 1'b1;
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                    baud_tick <= 1'b0;
                end

            // else nothing is happening reset counter
            end else begin
                baud_cnt <= '0;
                baud_tick <= 1'b0;
            end
        end
    end

    // Main receiver FSM
    // 1. Detect start
    // 2. Sample data and shift
    // 3. Check for stop bit and reset to idle
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            receiving <= 1'b0;
            bit_cnt <= '0;
            shift_reg <= '0;
            rx_data <= '0;
            rdy <= 1'b1;
        end else begin

            // Clear ready when requested
            if (clr_rdy)
                rdy <= 1'b0;

            // Look for start bit or first falling edge on the data line.
            if (!receiving) begin
                if (rx_sync == 2'b10) begin
                    receiving <= 1'b1;
                    // preload to half period so we sample in middle of start bit
                    baud_cnt <= 13'h1FFF >> 1;
                    bit_cnt <= 4'd0;
                    shift_reg <= '0;
                end

            end else begin

                // Sampling in the middle of the data line
                if (baud_tick) begin

                    // Build the shift register until byte is full
                    if (bit_cnt < 4'd9) begin
                        shift_reg <= {rx_sync[0], shift_reg[7:1]};  // shift LSB-first
                        bit_cnt <= bit_cnt + 1'b1;
                        
                    // After the data is full, wait for valid stop bit
                    end else if (rx_sync == 2'b11) begin
                        rx_data <= shift_reg;
                        rdy <= 1'b1;
                        // stop receiving and reset bit count
                        receiving <= 1'b0;
                        bit_cnt <= '0;
                    end

                end
            end
        end
    end

endmodule
