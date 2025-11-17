localparam S_INIT       = 3'd0;
localparam S_WAIT_INPUT = 3'd1;
localparam S_SLIDE      = 3'd2;
localparam S_MERGE      = 3'd3;
localparam S_SLIDE2     = 3'd4;
localparam S_CHECK      = 3'd5;
localparam S_SPAWN      = 3'd6;
localparam S_END        = 3'd7; // win or lose; use game_state to distinguish

module game_logic(
    input  wire       clk,
    input  wire       reset,
    input  wire       move_up,
    input  wire       move_down,
    input  wire       move_left,
    input  wire       move_right,
    output reg [11:0] board [0:15],
    output reg [15:0] score,
    output reg [1:0]  game_state  // 0=playing,1=win,2=lose
);

    reg [2:0] state, next_state;

    // direction register: 2 bits to remember which way we are moving
    reg [1:0] dir;  // 0=up,1=down,2=left,3=right

    // ==== 1. State register ====
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_INIT;
            // TODO: clear board, score, game_state
        end else begin
            state <= next_state;
        end
    end

    // ==== 2. Next-state logic ====
    always @* begin
        next_state = state;
        case (state)
            S_INIT:       next_state = S_WAIT_INPUT;

            S_WAIT_INPUT: begin
                if (move_up)       next_state = S_SLIDE;
                else if (move_down)next_state = S_SLIDE;
                else if (move_left)next_state = S_SLIDE;
                else if (move_right)next_state = S_SLIDE;
                // when we detect a button, we’ll also set dir (in sequential block)
            end

            S_SLIDE:      next_state = S_MERGE;
            S_MERGE:      next_state = S_SLIDE2;
            S_SLIDE2:     next_state = S_CHECK;
            S_CHECK: begin
                // TODO: if board did not change -> S_WAIT_INPUT
                //       else if win/lose -> S_END
                //       else -> S_SPAWN
            end
            S_SPAWN:      next_state = S_WAIT_INPUT;
            S_END: begin
                // stay here until reset
                next_state = S_END;
            end
        endcase
    end

    // ==== 3. Output / board update logic ====
    // Big always @(posedge clk) block:
    //   - reacts to state and dir
    //   - performs slides, merges, score update
    //   - uses a "previous board" copy to detect if changed
    //   - checks win/lose conditions
    //   - calls random generator to pick spawn index + value

    // TODO: write this block yourself, using comments like:
    //
    // if (state==S_WAIT_INPUT && move_left) dir <= DIR_LEFT;
    // if (state==S_SLIDE)    do_slide(dir);
    // if (state==S_MERGE)    do_merge(dir);
    // if (state==S_SLIDE2)   do_slide(dir);
    // if (state==S_SPAWN)    place new 2/4 using LFSR;
    // if (state==S_CHECK)    compute flags board_changed, has_2048, any_moves_left;

endmodule
