module Auth_blk_tb();

    //signals
    logic clk, rst_n;
    logic RX;
    logic clr_rdy;
    logic [7:0] tx_data;
    logic [9:0] tx_shft_reg;
    logic tx_done;
    logic trmt;
    logic [7:0] rx_data;
    logic rx_rdy;
    logic rider_off;
    logic pwr_up;

    Auth_blk iDUT(
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .rx_data(rx_data),
        .rx_rdy(rx_rdy),
        .rider_off(rider_off),
        .clr_rx_rdy(clr_rdy),
        .pwr_up(pwr_up)
    );
 
    UART_tx uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .trmt(trmt),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .tx_shft_reg(tx_shft_reg)
    );

    // Connect UART transmitter serial output (LSB of shift reg) to DUT RX
    assign RX = tx_shft_reg[0];

    always #5 clk <= ~clk;

        // Task to reset signals
    task rst_signals;
        // Initialize all signals
        rst_n = 1'b0;
        trmt = 0;
        rider_off = 1'b1;
        clr_rdy = 1'b0;
        tx_data = 8'h00;
        clk = 1'b1;
        @(posedge clk);
        // Hold reset for a few clocks
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
    endtask

    task transmit(input [7:0] byte_to_send);
        // Clear ready flag before starting new transmission
        clr_rdy = 1'b1;
        @(posedge clk);
        clr_rdy = 1'b0;
        
        // Setup data and initiate transmission
        tx_data = byte_to_send;
        trmt = 1'b1;
        @(posedge clk);
        trmt = 1'b0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        
        // Add a few cycles gap between transmissions
        repeat(100) @(posedge clk);
    endtask

    initial begin

        rst_signals;

        transmit(8'h53);
        if (pwr_up) begin
            $display("ERROR: pwr_up asserted before S was sent");
            $stop();
        end

        transmit(8'h47);
        if (pwr_up) begin
            $display("ERROR: pwr_up was asserted before the rider got on");
            $stop();
        end

        // rider is now on
        rider_off = 1'b0;

        transmit(8'h47);
        if (!pwr_up) begin
            $display("ERROR: pwr_up not asserted after G was transmitted");
            $stop();
        end else if (iDUT.state != 2'b01) begin
            $display("ERROR: we should be in the POWER state after transmitting G");
            $stop();
        end

        transmit(8'h53);
        if (!pwr_up) begin
            $display("ERROR: pwr_up did not remain asserted after transmitting S");
            $stop();
        end else if (iDUT.state != 2'b10) begin
            $display("ERROR: we should be in the BLE_DISCONNECTED state after transmitting S");
            $stop();
        end

        transmit(8'h53);
        if (!pwr_up) begin
            $display("ERROR: pwr_up did not remain asserted after transmitting S again");
            $stop();
        end else if (iDUT.state != 2'b10) begin
            $display("ERROR: we should still be in the BLE_DISCONNECTED state after transmitting S again");
            $stop();
        end

        // rider is now off
        rider_off = 1'b1;
        repeat(4) @(posedge clk);

        if (pwr_up) begin
            $display("ERROR: pwr_up should no longer be asserted after rider stepped off the hoverboard");
            $stop();
        end else if (iDUT.state != 2'b00) begin
            $display("ERROR: we should now be in the IDLE state");
            $stop();
        end

        // rider is back on
        rider_off = 1'b0;
        repeat(4) @(posedge clk);

        transmit(8'h47);
        if (!pwr_up) begin
            $display("ERROR: pwr_up not asserted after G was transmitted");
            $stop();
        end else if (iDUT.state != 2'b01) begin
            $display("ERROR: we should be in the POWER state after transmitting G");
            $stop();
        end 

        // Rider is back off
        rider_off = 1'b1;
        repeat(4) @(posedge clk);

        if (pwr_up) begin
            $display("ERROR: pwr_up should no longer be asserted after rider stepped off the hoverboard");
            $stop();
        end else if (iDUT.state != 2'b00) begin
            $display("ERROR: we should now be in the IDLE state");
            $stop();
        end

        $display("YAHOO! All tests passed");
        $stop();

    end

endmodule