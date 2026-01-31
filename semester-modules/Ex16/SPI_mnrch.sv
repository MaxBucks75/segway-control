// SCLK normally high, 16-bit packets only
// MOSI shifted on SCLK fall
// MISO sampled on SCLK rise

module SPI_mnrch( input logic clk,
                  input logic rst_n,    
                  output logic SS_n,            // Serf select
                  output logic SCLK,            // SPI clock
                  output logic MOSI,            // Mon out serf in
                  input logic MISO,             // Mon in serf out
                  input logic wrt,              // Write high for 1 clk to initiate SPI transation
                  input logic [15:0] wt_data,   // 2 write bytes to serf
                  output logic done,            // Assert when transaction is complete, deassert on next wrt
                  output logic [15:0] rd_data   // 2 read bytes from serf
);

// State definitions
typedef enum logic [1:0] {IDLE, SHIFT, DONE} state_t;
state_t state, nxt_state;

// Scanning for SS_n posedge at the end of transmission
logic SS_n_prev;
logic SS_n_curr;
logic SS_n_posedge;

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        SS_n_prev <= 1'b1;
        SS_n_curr <= 1'b1;
    end else begin
        SS_n_prev <= SS_n_curr;
        SS_n_curr <= SS_n;
    end
end

assign SS_n_posedge = (~SS_n_prev & SS_n_curr) ? 1'b1 : 1'b0;


// Clock definitions
logic [3:0] SCLK_div;   // Counter to alternate SCLK
logic ld_SCLK;          // Load the SCLK to 4'b1011 to initiate transaction

// Logic singals
logic shft;
logic smpl;
logic [4:0] smpl_cnt;       // Sample counter

// Unconditionally SCLK = the MSB of SCLK_div
assign SCLK = SCLK_div[3];

// SCLK, shift, sample, and sample counter logic
always_ff @(posedge clk, negedge rst_n) begin

    if (!rst_n) begin
    SCLK_div <= '1;
    smpl_cnt <= '0;
    shft <= 1'b0;
    smpl <= 1'b0;

    end else if (ld_SCLK)
        SCLK_div <= 4'b1011; // Create the "front porch" on first edge

    else if (!SS_n) begin

        // Shift when the counter is full (negedge)
        if (SCLK_div == 4'hF)
            shft <= 1'b1;
        else
            shft <= 1'b0;

        // Sample when the counter is half-full (posedge)
        if (SCLK_div == 4'b0111) begin
            smpl <= 1'b1;
            smpl_cnt <= smpl_cnt + 1'b1;
        end else
            smpl <= 1'b0;


        SCLK_div <= SCLK_div + 1'b1; // Unconditionally increment counter while in transaction

    // Final shift at the end of transmission
    end else if (SS_n_posedge)
        shft <= 1'b1;

    // Default values for clk and smpl counters when not in transaction
    else begin
        smpl_cnt <= '0;
        SCLK_div <= '1;
        shft <= 1'b0;
    end

end

logic [15:0] shift_reg;     // Shift register for both transmit and receive

// Shift register for MOSI output and MISO input
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        shift_reg <= 16'h0000;
    else if (wrt)
        shift_reg <= wt_data;  // Load new data when write asserted
    else if (smpl)
        shift_reg <= {shift_reg[14:0], MISO};  // Sample MISO on SCLK rise (or final sample at SS_n posedge)
end

// MOSI is always the MSB of shift register
assign MOSI = shift_reg[15];

// Read data is the current shift register contents
assign rd_data = shift_reg;

// State machine registers
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;
end

// Next state logic
always_comb begin

    // Default assignments
    nxt_state = state;
    ld_SCLK = 1'b0;
    SS_n = 1'b1;
    done = 1'b0;

    case (state)

        // Wait in IDLE until wrt is asserted
        IDLE: begin
            done = 1'b1;
            if (wrt) begin
                nxt_state = SHIFT;
                ld_SCLK = 1'b1;
            end
        end

        // Stay in shift state until all bits have been sampled, then shift one more time
        SHIFT: begin
            SS_n = 1'b0;
            if (smpl_cnt == 5'h10) begin
                nxt_state = DONE;
            end
        end

        // Reset signals and assert done
        DONE: begin
            SS_n = 1'b1;
            done = 1'b1;
            nxt_state = IDLE;
        end

        default: nxt_state = IDLE;

    endcase 
end

endmodule