//===========================================================
//  Module: inertial_integrator_tb
//  Purpose: Testbench for inertial_integrator module
//  Test sequence per Exercise 21 requirements:
//  1. Apply ptch_rt of 16'h1000 + PTCH_RT_OFFSET for 500 clocks (ptch trending negative)
//  2. Zero pitch rate (PTCH_RT_OFFSET) for 1000 clocks (fusion brings ptch toward zero)
//  3. Apply ptch_rt of PTCH_RT_OFFSET - 16'h1000 for 500 clocks (ptch trending positive) 
//  4. Zero pitch rate again for 1000 clocks (fusion brings ptch toward zero)
//  5. Set AZ to 16'h0800 and observe leveling off around ptch=100
//===========================================================

module inertial_integrator_tb();

    // Testbench signals
    logic        clk;
    logic        rst_n;
    logic        vld;
    logic signed [15:0] ptch_rt;
    logic signed [15:0] AZ;
    logic signed [15:0] ptch;
    
    // Constants from DUT
    localparam [15:0] PTCH_RT_OFFSET = 16'h0050;
    
    // Test phase tracking
    int phase;
    int clock_count;
    
    // Instantiate DUT
    inertial_integrator iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch_rt(ptch_rt),
        .AZ(AZ),
        .ptch(ptch)
    );
    
    // Generate 50MHz clock
    always begin
        clk = 0;
        #10;
        clk = 1; 
        #10;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 0;
        vld = 0;
        ptch_rt = 0;
        AZ = 0;
        phase = 0;
        clock_count = 0;
        
        // Wait a few clocks then release reset
        repeat(3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        
        // Enable valid signal for all tests
        vld = 1;
        
        $display("=== Starting Inertial Integrator Test ===");
        $display("Time: %0t - Phase 0: Reset complete", $time);
        
        //------------------------------------------------------------
        // Phase 1: Apply positive pitch rate for 500 clocks
        // ptch_rt = 16'h1000 + PTCH_RT_OFFSET
        // AZ = 16'h0000
        // Expected: ptch should trend negative (integrate -ptch_rt_comp)
        //------------------------------------------------------------
        phase = 1;
        ptch_rt = 16'h1000 + PTCH_RT_OFFSET;  // Large positive rate
        AZ = 16'h0000;                        // Zero AZ input
        
        $display("Time: %0t - Phase 1: Applying ptch_rt=0x%h, AZ=0x%h for 500 clocks", 
                 $time, ptch_rt, AZ);
        $display("Expected: ptch should trend negative");
        
        for (clock_count = 0; clock_count < 500; clock_count++) begin
            @(posedge clk);
            if (clock_count % 100 == 0) begin
                $display("  Clock %0d: ptch = %0d", clock_count, $signed(ptch));
            end
        end
        
        $display("Phase 1 complete: Final ptch = %0d", $signed(ptch));
        
        //------------------------------------------------------------
        // Phase 2: Zero out pitch rate for 1000 clocks
        // ptch_rt = PTCH_RT_OFFSET (compensated rate = 0)
        // Expected: fusion should bring ptch slowly toward zero
        //------------------------------------------------------------
        phase = 2;
        ptch_rt = PTCH_RT_OFFSET;  // Zero compensated rate
        
        $display("Time: %0t - Phase 2: Zero pitch rate for 1000 clocks", $time);
        $display("Expected: fusion should bring ptch toward zero");
        
        for (clock_count = 0; clock_count < 1000; clock_count++) begin
            @(posedge clk);
            if (clock_count % 200 == 0) begin
                $display("  Clock %0d: ptch = %0d", clock_count, $signed(ptch));
            end
        end
        
        $display("Phase 2 complete: Final ptch = %0d", $signed(ptch));
        
        //------------------------------------------------------------
        // Phase 3: Apply negative pitch rate for 500 clocks  
        // ptch_rt = PTCH_RT_OFFSET - 16'h1000
        // Expected: ptch should trend positive
        //------------------------------------------------------------
        phase = 3;
        ptch_rt = PTCH_RT_OFFSET - 16'h1000;  // Large negative rate
        
        $display("Time: %0t - Phase 3: Applying ptch_rt=0x%h for 500 clocks", 
                 $time, ptch_rt);
        $display("Expected: ptch should trend positive");
        
        for (clock_count = 0; clock_count < 500; clock_count++) begin
            @(posedge clk);
            if (clock_count % 100 == 0) begin
                $display("  Clock %0d: ptch = %0d", clock_count, $signed(ptch));
            end
        end
        
        $display("Phase 3 complete: Final ptch = %0d", $signed(ptch));
        
        //------------------------------------------------------------
        // Phase 4: Zero pitch rate again for 1000 clocks
        // Expected: fusion brings ptch toward zero again
        //------------------------------------------------------------
        phase = 4;
        ptch_rt = PTCH_RT_OFFSET;  // Zero compensated rate
        
        $display("Time: %0t - Phase 4: Zero pitch rate again for 1000 clocks", $time);
        $display("Expected: fusion should bring ptch toward zero");
        
        for (clock_count = 0; clock_count < 1000; clock_count++) begin
            @(posedge clk);
            if (clock_count % 200 == 0) begin
                $display("  Clock %0d: ptch = %0d", clock_count, $signed(ptch));
            end
        end
        
        $display("Phase 4 complete: Final ptch = %0d", $signed(ptch));
        
        //------------------------------------------------------------
        // Phase 5: Set AZ to 16'h0800 and observe leveling off
        // Expected: When ptch gets to about 100, it should level off
        // as ptch_acc should match ptch from fusion
        //------------------------------------------------------------
        phase = 5;
        AZ = 16'h0800;  // Non-zero AZ input
        
        $display("Time: %0t - Phase 5: Setting AZ=0x%h", $time, AZ);
        $display("Expected: ptch should level off around 100");
        
        for (clock_count = 0; clock_count < 1500; clock_count++) begin
            @(posedge clk);
            if (clock_count % 300 == 0) begin
                $display("  Clock %0d: ptch = %0d", clock_count, $signed(ptch));
            end
        end
        
        $display("Phase 5 complete: Final ptch = %0d", $signed(ptch));
        
        //------------------------------------------------------------
        // Test complete
        //------------------------------------------------------------
        $display("=== Test Complete ===");
        $display("Final values:");
        $display("  ptch = %0d", $signed(ptch));
        $display("  ptch_rt = 0x%h", ptch_rt);
        $display("  AZ = 0x%h", AZ);
        
        // Run a few more clocks to see steady state
        $display("Running 100 more clocks to observe steady state...");
        for (clock_count = 0; clock_count < 100; clock_count++) begin
            @(posedge clk);
            if (clock_count % 25 == 0) begin
                $display("  Clock %0d: ptch = %0d", clock_count, $signed(ptch));
            end
        end
        
        $display("Test finished at time %0t", $time);
        $stop;
    end
    
    // Optional: Monitor for debugging
    initial begin
        $monitor("Time=%0t Phase=%0d ptch_rt=0x%h AZ=0x%h ptch=%0d", 
                 $time, phase, ptch_rt, AZ, $signed(ptch));
    end

endmodule