module Auth_blk(
    input logic clk,
    input logic rst_n,
    input logic RX,
    input logic rider_off,
    output logic clr_rx_rdy,
    output logic pwr_up,
    output logic [7:0] rx_data,
    output logic rx_rdy
);

    // Define states
    typedef enum logic [1:0] {IDLE, POWER, BLE_DISCONNECTED} state_t;
    state_t state, nxt_state;

    // Instantiate UART receiver
    UART_rx uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .clr_rdy(clr_rx_rdy),
        .rx_data(rx_data),
        .rdy(rx_rdy)
    );

    // Logic to check when the S or G signals have been detected
    logic sig_g_received;
    logic sig_s_received;

    always_ff @(posedge clk, negedge rst_n) begin

        if (!rst_n) begin
            sig_s_received <= 1'b0;
            sig_g_received <= 1'b0;
        end else if (rx_rdy) begin

            // Check if we received an S or G
            if (rx_data == 8'h47)
                sig_g_received <= 1'b1;
            else if (rx_data == 8'h53)
                sig_s_received <= 1'b1;

            clr_rx_rdy <= 1'b1; // Clear the RX

        end else begin
            // default signals
            sig_s_received <= 1'b0;
            sig_g_received <= 1'b0;
            clr_rx_rdy <= 1'b0;
        end

    end

    // State machine registers
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    // State logic
    always_comb begin

        // Defaults
        pwr_up = 1'b0;
        nxt_state = state;

        case (state)

            // Wait for G signal to power up device
            IDLE: begin
                if (sig_g_received && !rider_off) begin
                    nxt_state = POWER;
                    pwr_up = 1'b1;
                end
            end

            // Wait until signal S is received
            POWER: begin
                pwr_up = 1'b1;
                if (sig_s_received)
                    nxt_state = BLE_DISCONNECTED;
                else if (rider_off) begin
                    nxt_state = IDLE;
                    pwr_up = 1'b0;
                end
            end

            // Keep the device powered until the rider is off
            BLE_DISCONNECTED: begin
                pwr_up = 1'b1;
                if (rider_off) begin
                    nxt_state = IDLE;
                    pwr_up = 1'b0;
                end
            end

            default: nxt_state = IDLE;            

        endcase

    end

endmodule
