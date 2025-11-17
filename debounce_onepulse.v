module debounce_onepulse #(
    parameter N_dc = 20 
)(
    input  wire CLK,
    input  wire RESET,
    input  wire PB,          // raw push button (active high)
    output wire DPB,         // debounced button level
    output wire SCEN         // single-clock pulse on rising edge
);

    // 1) Synchronize PB to CLK domain (2-FF synchronizer)
    reg pb_sync_0, pb_sync_1;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            pb_sync_0 <= 1'b0;
            pb_sync_1 <= 1'b0;
        end else begin
            pb_sync_0 <= PB;
            pb_sync_1 <= pb_sync_0;
        end
    end

    wire pb_stable_in = pb_sync_1;

    // 2) Debounce counter
    // If input stays different from current debounced value, count up.
    // If it matches, reset counter.
    reg [N_dc-1:0] db_count;
    reg pb_debounced;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            db_count     <= {N_dc{1'b0}};
            pb_debounced <= 1'b0;
        end else begin
            if (pb_stable_in == pb_debounced) begin
                // input matches current debounced state: reset counter
                db_count <= {N_dc{1'b0}};
            end else begin
                // input is different: increment counter
                db_count <= db_count + 1'b1;
                // when counter overflows (MSB=1), accept new state
                if (&db_count) begin    // all bits are 1
                    pb_debounced <= pb_stable_in;
                    db_count     <= {N_dc{1'b0}};
                end
            end
        end
    end

    assign DPB = pb_debounced;

    // 3) One-pulse (single-clock enable) on rising edge of debounced signal
    reg pb_debounced_prev;
    always @(posedge CLK or posedge RESET) begin
        if (RESET)
            pb_debounced_prev <= 1'b0;
        else
            pb_debounced_prev <= pb_debounced;
    end

    assign SCEN = pb_debounced & ~pb_debounced_prev;  // 1-clock pulse on 0→1

endmodule
