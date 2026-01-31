module SPI_mnrch_tb();

    // Testbench signals
    logic clk, rst_n;
    logic SS_n, SCLK, MOSI, MISO;
    logic wrt;
    logic [15:0] wt_data;
    logic done;
    logic [15:0] rd_data;
    logic INT;
    logic err;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Instantiate the SPI monarch (master)
    SPI_mnrch monarch(
        .clk(clk),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .wrt(wrt),
        .wt_data(wt_data),
        .done(done),
        .rd_data(rd_data)
    );

    // Instantiate the iNEMO device
    SPI_iNEMO1 iNEMO(
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );

    logic [15:0] rx_data;

    // Task for SPI transaction
    task automatic spi_trans(input [15:0] tx_data, output [15:0] rx_data);

        wt_data = tx_data;    // Set data to transmit

        @(posedge clk);       // Synchronize to clock
        wrt = 1'b1;           // Assert write for one clock

        @(posedge clk);
        wrt = 1'b0;           // Deassert write

        @(posedge done);      // Wait for transaction to complete
        repeat(20) @(posedge clk);
        rx_data = rd_data;    // Capture received data

    endtask

    // Task to reset signals
    task rst_signals;
        // Initialize all signals
        rst_n = 1'b0;
        wrt = 1'b0;
        wt_data = 16'h0000;
        
        // Assert resets
        @(posedge clk);
        rst_n = 1'b0;
        force iNEMO.POR_n = 1'b0;  // Need to use force/release for hierarchical signals
        
        // Hold in reset for a few clocks
        repeat(4) @(posedge clk);
        
        // Release resets
        rst_n = 1'b1;
        release iNEMO.POR_n;       // Release hierarchical signal
        
        // Wait for iNEMO internal clock to stabilize
        repeat(10) @(posedge clk);
    endtask

    // Test stimulus
    initial begin

        rst_signals;
        err = 1'b0;

        // Test 1: Random data transaction j lookin at waveforms 
        repeat(10) @(posedge clk);
        spi_trans(16'hA5A5, rd_data);

        // Allow some time between transactions
        repeat(100) @(posedge clk);

        // Test 2: iNEMO Transactions

        // Transaction 1: Read WHO_AM_I register (should return 0x6A)
        spi_trans(16'h8F00, rx_data);
        if (rx_data[7:0] !== 8'h6A) begin
            $display("ERROR: WHO_AM_I register read failed. Expected 6A, got %h", rx_data[7:0]);
            err = 1'b1;
        end else
            $display("WHO_AM_I register read passed");

        // Allow some time between transactions
        repeat(100) @(posedge clk);

        // Transaction 2: Write to INT config register, nemo_setup signal should go high
        spi_trans(16'h0D02, rx_data);
        $display("Wrote INT config register. Response = %h", rx_data);
        
        // Wait a few clocks to let register update
        repeat(10) @(posedge clk);
        
        // Check NEMO_setup and register value
        $display("NEMO register[0D] = %h", iNEMO.registers[8'h0D]);
        $display("NEMO_setup = %b", iNEMO.NEMO_setup);

        // Wait until INT is asserted
        fork
            begin : timeout1
                repeat(50000) @(posedge clk);
                $display("ERROR: Timeout waiting for interrupt pin to assert");
                $stop();
            end
            begin
                @(posedge INT);
                $display("Interrupt detected");
                disable timeout1;
            end     
        join

        if (!iNEMO.NEMO_setup) begin
            $display("ERROR: nemo_setup is still low");
            err = 1'b1;
        end

        // Allow some time between transactions
        repeat(100) @(posedge clk);

        // Transaction 3: Read yaw rate data
        spi_trans(16'hA200, rx_data);
        $display("Read yaw rate data = %h", rx_data[7:0]);
        if (rx_data[7:0] !== 8'h63) begin
            $display("ERROR: Yaw rate data incorrect. Expected 63, got %h", rx_data[7:0]);
            err = 1'b1;
        end

        // Wait until INT is de-asserted
        fork
            begin : timeout2
                repeat(50000) @(posedge clk);
                $display("ERROR: Timeout waiting for interrupt pin to de-assert");
                $stop();
            end
            begin
                @(posedge INT);
                $display("Interrupt detected");
                disable timeout2;
            end     
        join

        if (!err) $display("YAHOO! All tests passed");

        $stop;

    end


endmodule
