module piezo_drv #(parameter fast_sim = 1) (
    input logic clk,        // clk is 50 MHz
    input logic rst_n,
    input logic en_steer,
    input logic too_fast,
    input logic batt_low,
    output logic piezo,     // Output square wave
    output logic piezo_n    // Complement of piezo wave
);

// State definitions
typedef enum logic [2:0] {IDLE, NTE_G6, NTE_C7, FRST_NTE_E7, FRST_NTE_G7, SCND_NTE_E7, SCND_NTE_G7} state_t;
state_t state, nxt_state;

// Counter to determine the duration of the note being played

/*
    NOTE DURATION
    G6   2^23 (6'h800000)
    C7   2^23 (6'h800000)
    E7   2^23 (6'h800000)
    G7   2^23 + 2^22 (6'hC00000)
    E7   2^22 (6'4000000)
    G7   2^25 (7'h2000000)
*/

logic [24:0] duration_tmr;
logic duration_tmr_done;

generate

if (fast_sim) begin : FAST_DURATION

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            duration_tmr <= '0;
            duration_tmr_done <= 1'b0;
        end
        else if (state == NTE_G6 || state == NTE_C7 || state == FRST_NTE_E7) begin
            if (duration_tmr < 24'h800000) begin
                duration_tmr <= duration_tmr + 6'h20;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else if (state == FRST_NTE_G7) begin
            if (duration_tmr < 24'hC00000) begin
                duration_tmr <= duration_tmr + 6'h20;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else if (state == SCND_NTE_E7) begin
            if (duration_tmr < 24'h400000) begin
                duration_tmr <= duration_tmr + 6'h20;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else if (state == SCND_NTE_G7) begin
            if (duration_tmr < 25'h2000000) begin
                duration_tmr <= duration_tmr + 6'h20;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else begin
            duration_tmr <= '0;
            duration_tmr_done <= 1'b0;
        end
    end

end else begin

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            duration_tmr <= '0;
            duration_tmr_done <= 1'b0;
        end
        else if (state == NTE_G6 || state == NTE_C7 || state == FRST_NTE_E7) begin
            if (duration_tmr < 24'h800000) begin
                duration_tmr <= duration_tmr + 1'b1;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else if (state == FRST_NTE_G7) begin
            if (duration_tmr < 24'hC00000) begin
                duration_tmr <= duration_tmr + 1'b1;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else if (state == SCND_NTE_E7) begin
            if (duration_tmr < 24'h400000) begin
                duration_tmr <= duration_tmr + 1'b1;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else if (state == SCND_NTE_G7) begin
            if (duration_tmr < 25'h2000000) begin
                duration_tmr <= duration_tmr + 1'b1;
                duration_tmr_done <= 1'b0;
            end else begin
                duration_tmr <= '0;
                duration_tmr_done <= 1'b1;
            end
        end
        else begin
            duration_tmr <= '0;
            duration_tmr_done <= 1'b0;
        end
    end

end

endgenerate


// 28-bit timer that counts to 3 seconds which is d'150,000,000 (0x08F0D180)
logic [27:0] repeat_tmr; 
logic repeat_tmr_done;

generate

    if (fast_sim) begin : FAST_REPEAT

        always_ff @(posedge clk, negedge rst_n) begin

            if (!rst_n) begin
                repeat_tmr <= '0;
                repeat_tmr_done <= 1'b1;

            // When we aren't idle count every 3/64 seconds
            end else if (en_steer) begin
                if (repeat_tmr < 28'h08F0D180) begin
                    repeat_tmr <= repeat_tmr + 6'h20;
                    repeat_tmr_done <= 1'b0;
                end else begin
                    repeat_tmr <= '0;
                    repeat_tmr_done <= 1'b1;
                end
            end else begin
                repeat_tmr <= '0;
                repeat_tmr_done <= 1'b1;
            end
        end

    end else begin

        always_ff @(posedge clk, negedge rst_n) begin

            if (!rst_n) begin
                repeat_tmr <= '0;
                repeat_tmr_done <= 1'b1;

            // When we aren't idle count every 3 seconds
            end else if (en_steer) begin
                if (repeat_tmr < 28'h08F0D180) begin
                    repeat_tmr <= repeat_tmr + 1'b1;
                    repeat_tmr_done <= 1'b0;
                end else begin
                    repeat_tmr <= '0;
                    repeat_tmr_done <= 1'b1;
                end
            end else begin
                repeat_tmr <= '0;
                repeat_tmr_done <= 1'b1;
            end
        end

    end

endgenerate

// Local parameters with the frequency for the notes in Charge Fanfare (Num clk cycles)
// # clk cycles = 50 MHz / Note frequency (Hz)
// Note frequency counters (values fit in 16 bits)
localparam int G6_num_cycles = 16'd31888;
localparam int C7_num_cycles = 16'd23889;
localparam int E7_num_cycles = 16'd18961;
localparam int G7_num_cycles = 16'd15944;

logic [14:0] freq_tmr;      // Used to generate a square wave based on the note being played

generate

    if (fast_sim) begin : FAST_FREQ

        always_ff @(posedge clk, negedge rst_n) begin

            if (!rst_n) begin
                freq_tmr <= '0;
                piezo <= 1'b0;
            end
            else if (state == NTE_G6) begin
                if (freq_tmr <= G6_num_cycles) begin
                    freq_tmr <= freq_tmr + 6'h20;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else if (state == NTE_C7) begin
                if (freq_tmr <= C7_num_cycles) begin
                    freq_tmr <= freq_tmr + 6'h20;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else if (state == FRST_NTE_E7 || state == SCND_NTE_E7) begin
                if (freq_tmr <= E7_num_cycles) begin
                    freq_tmr <= freq_tmr + 6'h20;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else if (state == FRST_NTE_G7 || state == SCND_NTE_G7) begin
                if (freq_tmr <= G7_num_cycles) begin
                    freq_tmr <= freq_tmr + 6'h20;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else begin
                freq_tmr <= '0;
                piezo <= 1'b0;
            end
            
        end

    end else begin

    
        always_ff @(posedge clk, negedge rst_n) begin

            if (!rst_n) begin
                freq_tmr <= '0;
                piezo <= 1'b0;
            end
            else if (state == NTE_G6) begin
                if (freq_tmr <= G6_num_cycles) begin
                    freq_tmr <= freq_tmr + 1'b1;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else if (state == NTE_C7) begin
                if (freq_tmr <= C7_num_cycles) begin
                    freq_tmr <= freq_tmr + 1'b1;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else if (state == FRST_NTE_E7 || state == SCND_NTE_E7) begin
                if (freq_tmr <= E7_num_cycles) begin
                    freq_tmr <= freq_tmr + 1'b1;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else if (state == FRST_NTE_G7 || state == SCND_NTE_G7) begin
                if (freq_tmr <= G7_num_cycles) begin
                    freq_tmr <= freq_tmr + 1'b1;
                end else begin
                    freq_tmr <= '0;
                    piezo <= ~piezo;
                end
            end

            else begin
                freq_tmr <= '0;
                piezo <= 1'b0;
            end
            
        end
    
    end

endgenerate

assign piezo_n = ~piezo;

// State machine registers
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;
end


always_comb begin

    nxt_state = state;

    case (state)

        IDLE: begin

            if (en_steer && (too_fast || (repeat_tmr_done && !batt_low)))
                nxt_state = NTE_G6;
            else if (batt_low && repeat_tmr_done)
                nxt_state = SCND_NTE_G7;

        end

        NTE_G6: begin

            if (duration_tmr_done) begin
                if (!too_fast && batt_low)
                    nxt_state = IDLE;
                else
                    nxt_state = NTE_C7;
            end else if (!en_steer && !batt_low)
                nxt_state = IDLE;


        end

        NTE_C7: begin

            if (duration_tmr_done) begin
                if (!too_fast && batt_low)
                    nxt_state = NTE_G6;
                else
                    nxt_state = FRST_NTE_E7;
            end else if (!en_steer && !batt_low)
                nxt_state = IDLE;

        end

        FRST_NTE_E7: begin

            if (duration_tmr_done) begin
                if (too_fast)
                    nxt_state = NTE_G6;
                else if (batt_low) 
                    nxt_state = NTE_C7;
                else
                    nxt_state = FRST_NTE_G7;
            end else if (!en_steer && !batt_low)
                nxt_state = IDLE;     

        end

        FRST_NTE_G7: begin

            if (duration_tmr_done) begin
                if (too_fast)
                    nxt_state = NTE_G6;
                else if (batt_low)
                    nxt_state = FRST_NTE_E7;
                else
                    nxt_state = SCND_NTE_E7;
            end else if (!en_steer && !batt_low)
                nxt_state = IDLE;


        end

        SCND_NTE_E7: begin

            if (duration_tmr_done) begin
                if (too_fast)
                    nxt_state = NTE_G6;
                else if (batt_low)
                    nxt_state = FRST_NTE_G7;
                else
                    nxt_state = SCND_NTE_G7;
            end else if (!en_steer && !batt_low)
                nxt_state = IDLE;

        end

        SCND_NTE_G7: begin

            if (duration_tmr_done) begin
                if (too_fast)
                    nxt_state = NTE_G6;
                else if (batt_low)
                    nxt_state = SCND_NTE_E7;
                else
                    nxt_state = IDLE;
            end else if (!en_steer && !batt_low)
                nxt_state = IDLE;

        end


    endcase

end

endmodule
