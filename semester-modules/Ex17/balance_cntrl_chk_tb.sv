module balance_cntrl_chk_tb;

	logic clk;

	// Stimulus register and memories
	logic [48:0] stim_reg;
	logic [48:0] stim_mem [0:1499];
	logic [24:0] resp_mem [0:1499];

	// Signals derived from stim_reg
	logic        rst_n;
	logic        vld;
	logic signed [15:0] ptch;
	logic signed [15:0] ptch_rt;
	logic        pwr_up;
	logic        rider_off;
	logic [11:0] steer_pot;
	logic        en_steer;

	// Assign signals from te stimulus hex file
	assign rst_n     = stim_reg[48];
	assign vld       = stim_reg[47];
	assign ptch      = $signed(stim_reg[46:31]);
	assign ptch_rt   = $signed(stim_reg[30:15]);
	assign pwr_up    = stim_reg[14];
	assign rider_off = stim_reg[13];
	assign steer_pot = stim_reg[12:1];
	assign en_steer  = stim_reg[0];

	// DUT outputs
	logic signed [11:0] lft_spd;
	logic signed [11:0] rght_spd;
	logic               too_fast;
	logic [7:0]         ss_tmr;      // will be forced
	logic signed [11:0] PID_cntrl;   // not used in checker but left connected

	// Instantiate iDUT
	balance_cntrl #(.fast_sim(1)) iDUT (
		.clk(clk),
		.rst_n(rst_n),
		.vld(vld),
		.ptch(ptch),
		.ptch_rt(ptch_rt),
		.pwr_up(pwr_up),
		.rider_off(rider_off),
		.steer_pot(steer_pot),
		.en_steer(en_steer),
		.lft_spd(lft_spd),
		.rght_spd(rght_spd),
		.too_fast(too_fast),
		.ss_tmr(ss_tmr),
		.PID_cntrl(PID_cntrl)
	);

	// Test variables
	integer i;
	integer errors;
	integer error_too_fast;
	integer error_lft;
	integer error_rght;
	logic signed [11:0] expected_lft;
	logic signed [11:0] expected_rght;
	logic expected_too_fast;

	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	initial begin

		// Read files
		$display("Reading stimulus and response files...");
		$readmemh("balance_cntrl_stim.hex", stim_mem);
		$readmemh("balance_cntrl_resp.hex", resp_mem);

		// Force soft-start timer
		force iDUT.ss_tmr = 8'hFF;

		// Initialize error integers
		errors = 0;
		error_lft = 0;
		error_rght = 0;
		error_too_fast = 0;

		// Test all 1500 vectors
		for (i = 0; i < 1500; i = i + 1) begin

			stim_reg = stim_mem[i];

			// wait posedge clk then 1 time unit from specification
			@(posedge clk);
			#1;

			expected_lft  = $signed(resp_mem[i][24:13]);
			expected_rght = $signed(resp_mem[i][12:1]);
			expected_too_fast = resp_mem[i][0];

			// If one of the value don't match the expected value, display error message and increment errors
			if ((lft_spd != expected_lft) || (rght_spd != expected_rght) || (too_fast != expected_too_fast)) begin
				$display("ERR ON VECTOR: %0d |  LEFT  |  RIGHT  | TOO FAST", i);
				$display("--------------------------------------------------");
				$display("          EXPECTED |  %0d  |  %0d    |  %0d", expected_lft, expected_rght, expected_too_fast);
				$display("--------------------------------------------------");
				$display("               GOT |  %0d  |  %0d    |  %0d", lft_spd, rght_spd, too_fast);
				$display("--------------------------------------------------");

				errors = errors + 1'b1;
			end else begin
				$display("SUCCESS ON VECTOR: %0d |  LEFT  |  RIGHT  | TOO FAST", i);
				$display("--------------------------------------------------");
				$display("              EXPECTED |  %0d  |  %0d    |  %0d", expected_lft, expected_rght, expected_too_fast);
				$display("--------------------------------------------------");
				$display("                   GOT |  %0d  |  %0d    |  %0d", lft_spd, rght_spd, too_fast);
				$display("--------------------------------------------------");
			end

			// Count the number of mismatch errors for left, right, and too fast respectively
			if (lft_spd != expected_lft) error_lft = error_lft + 1'b1;
			if (rght_spd != expected_rght) error_rght = error_rght + 1'b1;
			if (too_fast != expected_too_fast) error_too_fast = error_too_fast + 1'b1;

		end

		if (errors == 0) $display("YAHOO! All tests passed");

		// Error printing
		else begin
			$display("FAIL: %0d mismatches out of %0d vectors", errors, 1500);
			$display("Num left mismatches: %0d", error_lft);
			$display("Num right mismatches: %0d", error_rght);
			$display("Num too fast mismatches: %0d", error_too_fast);
		end

		release iDUT.ss_tmr;

		$stop();

	end

endmodule

