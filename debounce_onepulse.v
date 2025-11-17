module btn_onepulse (
    input  wire clk,         // system clock (100 MHz)
    input  wire reset,       // synchronous or async reset
    input  wire btn_in,      // raw button input
    output wire pulse        // 1-clock-wide pulse
);

    // ---------------------------
    // 1) Synchronize the button
    // ---------------------------
    reg sync_0, sync_1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= btn_in;
            sync_1 <= sync_0;
        end
    end

    // ---------------------------
    // 2) Debounce logic
    // ---------------------------
    // A small counter that increments only when the input stays stable.
    // If unstable -> reset counter.
    // Once counter overflows, accept new stable state.

    reg [19:0] db_count;       // ~10ms debounce at 100MHz
    reg        debounced;      // debounced button level

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            db_count   <= 20'd0;
            debounced  <= 1'b0;
        end else begin
            if (sync_1 == debounced) begin
                // input matches the stable value → reset counter
                db_count <= 20'd0;
            end else begin
                // input changed → start counting stability time
                db_count <= db_count + 20'd1;

                // If counter overflow → accept new input
                if (&db_count) begin    // all bits = 1
                    debounced <= sync_1;
                    db_count  <= 20'd0;
                end
            end
        end
    end

    // ---------------------------
    // 3) One-pulse generator
    // ---------------------------
    reg debounced_prev;

    always @(posedge clk or posedge reset) begin
        if (reset)
            debounced_prev <= 1'b0;
        else
            debounced_prev <= debounced;
    end

    // SCEN pulse: 1 clock cycle on rising edge
    assign pulse = debounced & ~debounced_prev;

endmodule
