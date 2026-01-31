module UART_tb();

    //signals
    logic clk, rst_n;
    logic [7:0] tx_data;
    logic trmt;
    logic tx_done;
    logic [9:0] tx_shft_reg;
    logic RX;
    logic clr_rdy;
    logic [7:0] rx_data;
    logic rx_rdy;

    // Connect TX output to RX input
    assign RX = tx_shft_reg[0];

    // Instantiate UART transmitter
    UART_tx uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .trmt(trmt),
    .tx_data(tx_data),
    .tx_done(tx_done),
    .tx_shft_reg(tx_shft_reg)
    );

    // Instantiate UART receiver
    UART_rx uart_rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .RX(RX),
    .clr_rdy(clr_rdy),
    .rx_data(rx_data),
    .rdy(rx_rdy)
    );

    initial begin

        // Initialize signals
        clk = 0;
        trmt = 0;
        tx_data = 8'h00;
        clr_rdy = 1;

        // reset
        #50; rst_n = 0;
        #50; rst_n = 1;

        // First byte transmission
        #50; 
        clr_rdy = 0;

        trmt = 1;
        #50; 
        trmt = 0;

        // Check for start and stop bit
        if (tx_shft_reg[0] != 1'b0) begin
            $display("FAIL: Start bit not 0 for 8'h00");
            $stop();
        end
        if (tx_shft_reg[9] !== 1'b1) begin
            $display("FAIL: Stop bit not 1 for 8'h00");
            $stop();
        end

        wait(tx_done);  // wait for tx to finish
        wait(rx_rdy);   // wait for rx to finish

        // Check for correct byte
        if (rx_data == 8'h00)
            $display("PASS: Sent 8'h00, Received %02X", rx_data);
        else begin
            $display("FAIL: Sent 8'h00, Received %02X", rx_data);
            $stop();
        end

        // Clear RX
        #10; clr_rdy = 1;
        #10; clr_rdy = 0;

        #50;

        // Second byte transmission
        tx_data = 8'h55;

        trmt = 1;
        #10; 
        trmt = 0;

        // Check for start and stop bit
        if (tx_shft_reg[0] != 1'b0) begin
            $display("FAIL: Start bit not 0 for 8'h55");
            $stop();
        end
        if (tx_shft_reg[9] !== 1'b1) begin
            $display("FAIL: Stop bit not 1 for 8'h55");
            $stop();
        end

        wait(tx_done);  // wait for tx to finish
        wait(rx_rdy);   // wait for rx to finish

        // Check for correct byte
        if (rx_data == 8'h55)
            $display("PASS: Sent 8'h55, Received %02X", rx_data);
        else begin
            $display("FAIL: Sent 8'h55, Received %02X", rx_data);
            $stop();
        end

        // Clear RX
        #10; clr_rdy = 1;
        #10; clr_rdy = 0;

        #50;

        // Third byte transmission
        tx_data = 8'hFF;
        trmt = 1;
        #10; 
        trmt = 0;

        // Check for start and stop bit
        if (tx_shft_reg[0] != 1'b0) begin
            $display("FAIL: Start bit not 0 for 8'hFF");
            $stop();
        end
        if (tx_shft_reg[9] !== 1'b1) begin
            $display("FAIL: Stop bit not 1 for 8'hFF");
            $stop();
        end

        wait(tx_done);  // wait for tx to finish
        wait(rx_rdy);   // wait for rx to finish

        // Check for correct byte
        if (rx_data == 8'hFF)
            $display("PASS: Sent 8'hFF, Received %02X", rx_data);
        else begin
            $display("FAIL: Sent 8'hFF, Received %02X", rx_data);
            $stop();
        end

        $display("YAHOO! All tests passed");
        $stop();
    
    end

    always #5 clk <= ~clk;

endmodule