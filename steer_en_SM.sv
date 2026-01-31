module steer_en_SM(clk, rst_n, tmr_full, sum_gt_min, sum_lt_min,
                  diff_gt_1_4, diff_gt_15_16, clr_tmr,
                  en_steer, rider_off);

  input clk;			    	  // 50MHz clock
  input rst_n;				    // Active low asynch reset
  input tmr_full;		   	  // asserted when timer reaches 1.3 sec
  input sum_gt_min;			  // asserted when left and right load cells together exceed min rider weight
  input sum_lt_min;			  // asserted when left_and right load cells are less than min_rider_weight
  input diff_gt_1_4;		  // asserted if load cell difference exceeds 1/4 sum (rider not situated)
  input diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  
  output logic clr_tmr;		// clears the 1.3sec timer
  output logic en_steer;	// enables steering (goes to balance_cntrl)
  output logic rider_off;	// held high in intitial state when waiting for sum_gt_min

  // Using enums for state names
  typedef enum logic [1:0] {
    INITIAL,
    STABILIZE,
    STEERING_EN
  } state_t;

  state_t state, nxt_state;

  // Initialize on reset and update current state
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= INITIAL;
    end else begin
      state <= nxt_state;
    end
  end

  // Combinational logic: determine next state and outputs
  always_comb begin
    // Default assignments
    nxt_state = state;
    clr_tmr   = 1'b0;
    en_steer  = 1'b0;
    rider_off = 1'b1;

    case (state)

      INITIAL: begin

        // Wait until the sum is greater than min weight
        if (sum_gt_min) begin
          nxt_state = STABILIZE;
        end

      end

      STABILIZE: begin

        // default
        rider_off = 1'b0;

        // If sum is less than min (driver fell off) return to initial
        if (sum_lt_min) begin
          nxt_state = INITIAL;
          rider_off = 1'b1;
          clr_tmr   = 1'b1; 
        end

        // If the user is off balance (diff_gt_1_4 is high) clear the stabilize timer 
        else if (diff_gt_1_4) begin
          clr_tmr = 1'b1;
        end

        // If the user has been balanced for the full 1.3 seconds, enable steering
        else if (tmr_full) begin
          nxt_state = STEERING_EN;
        end
        
        // else make sure timer is incrementing
        else begin
          clr_tmr = 1'b0;
        end
      end

      STEERING_EN: begin
        // Active steering state defaults
        rider_off = 1'b0;
        en_steer  = 1'b1;

        // If the user becomes severely unbalanced or steps off, return to stabilize state
        if (diff_gt_15_16) begin
          nxt_state = STABILIZE;
          rider_off = 1'b1;
          en_steer  = 1'b0;
        end

        // If the user falls off, return to initial state
        else if (sum_lt_min) begin
          nxt_state = INITIAL;
          rider_off = 1'b1;
          en_steer  = 1'b0;
        end
      end

    endcase
  end
  
endmodule