module UART_tx(
    input logic clk,                // clock!
    input logic rst_n,              // Asynch active low reset
    input logic trmt,               // Assert for one clk to initiate transmission
    input logic [7:0] tx_data,      // Byte to transmit    
    output logic tx_done,           // Assert when the byte is done transmitting and hold high
    output logic [9:0] tx_shft_reg, // Full output register with start/stop bit 
);

    // Internal signals
    logic [3:0] bit_cnt;                // counts transmitted bits (0..9)
    logic transmitting;                 // high while byte is being sent
    logic [12:0] baud_cnt;              // baud divider counter
    logic baud_tick;                    // one-clock pulse when it's time to shift
    logic load;                         // load shift register this cycle

    // Load is a pulse when trmt is asserted and we're not already transmitting
    assign load = trmt & ~transmitting;

    // Baud count control
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            baud_cnt <= '0;
            baud_tick <= 1'b0;
        end else begin

            // if we are loading or transmitting, run the counter
            if (load || transmitting) begin
                if (baud_cnt == 13'h1FFF) begin
                    baud_cnt <= '0;
                    baud_tick <= 1'b1;  // assert baud_tick at end of counter

                // increment the baud counter
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                    baud_tick <= 1'b0;
                end

            // Nothing is happening, stop the baud counter
            end else begin
                baud_cnt <= '0;
                baud_tick <= 1'b0;
            end

        end
    end

    // Shift-register and transmit control
    // 1. load {stop(1), data[7:0], start(0)} into tx_shft_reg. 
    // 2. On each baud_tick shift right one bit (LSB is the serial output). 
    // 3. After 10 bits are shifted, mark done and hold idle state.
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            tx_shft_reg <= 10'h3FF; // idle line is all one
            bit_cnt <= '0;          
            transmitting <= 1'b0;
            tx_done <= 1'b1;
        end else begin

            // Start a new transmission
            if (load) begin
                tx_shft_reg <= {1'b1, tx_data, 1'b0}; // {stop, data[7:0], start}
                bit_cnt <= 4'd0;
                transmitting <= 1'b1;
                tx_done <= 1'b0;

            end else if (baud_tick && transmitting) begin
                // Shift tx line right and increment bit counter
                tx_shft_reg <= {1'b1, tx_shft_reg[9:1]};
                bit_cnt <= bit_cnt + 1'b1;

                // If we've shifted all 10 bits, finish transmission
                if (bit_cnt == 4'd9) begin
                    transmitting <= 1'b0;
                    tx_done <= 1'b1;
                end

            end
            // else hold state
        end
    end

endmodule