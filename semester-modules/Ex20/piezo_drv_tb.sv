module piezo_drv_tb;

  logic clk;
  logic rst_n;
  logic en_steer;
  logic too_fast;
  logic batt_low;
  logic piezo, piezo_n;

  // DUT instantiation
  piezo_drv #(.fast_sim(1)) dut (
      .clk(clk),
      .rst_n(rst_n),
      .en_steer(en_steer),
      .too_fast(too_fast),
      .batt_low(batt_low),
      .piezo(piezo),
      .piezo_n(piezo_n)
  );

  always #5 clk = ~clk;

  // Stimulus process
  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    en_steer = 1'b0;
    too_fast = 1'b0;
    batt_low = 1'b0;

    repeat(50) @(posedge clk);
    rst_n = 1'b1;
    repeat(50) @(posedge clk);

    // Should see count up through notes
    en_steer = 1'b1;
    while (dut.state != 3'h6) begin
      @(posedge clk);
    end

    // Should see reversal of notes
    batt_low = 1'b1;
    rst_n = 1'b0;
    repeat(1000) @(posedge clk);
    rst_n = 1'b1;
    repeat(1000) @(posedge clk);


    while (dut.state != 3'h4) begin
      @(posedge clk);
    end

    // Should see first 3 notes being played
    too_fast = 1'b1;
    rst_n = 1'b0;
    repeat(1000) @(posedge clk);
    rst_n = 1'b1;
    repeat(1000) @(posedge clk);

    while (dut.state != 3'h3) begin
      @(posedge clk);
    end

    $stop();

  end

endmodule
