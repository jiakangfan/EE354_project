// State encoding
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
    output reg [11:0] board [0:15],   // tile values: 0,2,4,8,...
    output reg [15:0] score,
    output reg [1:0]  game_state      // 0=playing,1=win,2=lose
);

    // Direction codes
    localparam DIR_UP    = 2'd0;
    localparam DIR_DOWN  = 2'd1;
    localparam DIR_LEFT  = 2'd2;
    localparam DIR_RIGHT = 2'd3;

    reg [2:0] state, next_state;
    reg [1:0] dir;

    // previous board to detect change
    reg [11:0] prev_board [0:15];

    // scratch row buffers used for sliding (global so tasks can use them)
    reg [11:0] row   [0:3];
    reg [11:0] newrow[0:3];

    integer i, r, c;
    
    wire [9:0] rnd;

    lfsr_random rng (
        .clk   (clk),
        .reset (reset),
        .rnd   (rnd)
    );

    wire [3:0] rand_index   = rnd[3:0];  // 0..15, used for random start index
    wire       rand_is_four = rnd[4];    // used as 2/4 selector

    // ---------------------------------------------------------
    // Combinational flags for CHECK state
    // ---------------------------------------------------------
    reg board_changed_c;
    reg has_2048_c;
    reg moves_left_c;

    integer idx;

    always @* begin
        board_changed_c = 1'b0;
        has_2048_c      = 1'b0;
        moves_left_c    = 1'b0;

        // check change + presence of 2048 + empties
        for (i = 0; i < 16; i = i + 1) begin
            if (board[i] != prev_board[i])
                board_changed_c = 1'b1;
            if (board[i] == 12'd2048)
                has_2048_c = 1'b1;
            if (board[i] == 12'd0)
                moves_left_c = 1'b1;   // empty cell → at least one move exists
        end

        // check equal neighbors (right & down) to see if merges still possible
        for (r = 0; r < 4; r = r + 1) begin
            for (c = 0; c < 4; c = c + 1) begin
                idx = r*4 + c;
                if (c < 3 && board[idx] == board[idx+1] && board[idx] != 0)
                    moves_left_c = 1'b1;
                if (r < 3 && board[idx] == board[idx+4] && board[idx] != 0)
                    moves_left_c = 1'b1;
            end
        end
    end

    // ---------------------------------------------------------
    // State register & basic reset / init
    // ---------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= S_INIT;
            score      <= 16'd0;
            game_state <= 2'd0;

            for (i = 0; i < 16; i = i + 1) begin
                board[i]      <= 12'd0;
                prev_board[i] <= 12'd0;
            end
        end else begin
            state <= next_state;
        end
    end

    // ---------------------------------------------------------
    // Next-state logic
    // ---------------------------------------------------------
    always @* begin
        next_state = state;
        case (state)
            S_INIT:       next_state = S_WAIT_INPUT;

            S_WAIT_INPUT: begin
                if (move_up || move_down || move_left || move_right)
                    next_state = S_SLIDE;
            end

            S_SLIDE:      next_state = S_MERGE;
            S_MERGE:      next_state = S_SLIDE2;
            S_SLIDE2:     next_state = S_CHECK;

            S_CHECK: begin
                if (!board_changed_c)
                    next_state = S_WAIT_INPUT;        // illegal move, ignore
                else if (has_2048_c || !moves_left_c)
                    next_state = S_END;               // win or lose
                else
                    next_state = S_SPAWN;             // normal move, spawn tile
            end

            S_SPAWN:      next_state = S_WAIT_INPUT;

            S_END:        next_state = S_END;         // stay here until reset
        endcase
    end

    // ---------------------------------------------------------
    // Tasks for sliding & merging
    // ---------------------------------------------------------

    // Slide all tiles LEFT
       // Slide all tiles LEFT
    task slide_left;
        integer rr, cc, w;
        begin
            for (rr = 0; rr < 4; rr = rr + 1) begin
                // read row
                for (cc = 0; cc < 4; cc = cc + 1)
                    row[cc] = board[rr*4 + cc];

                // clear newrow
                for (cc = 0; cc < 4; cc = cc + 1)
                    newrow[cc] = 12'd0;

                // pack non-zeros to the left
                w = 0;
                for (cc = 0; cc < 4; cc = cc + 1) begin
                    if (row[cc] != 0) begin
                        newrow[w] = row[cc];
                        w = w + 1;
                    end
                end

                // write back
                for (cc = 0; cc < 4; cc = cc + 1)
                    board[rr*4 + cc] <= newrow[cc];
            end
        end
    endtask

    // Slide all tiles RIGHT
    task slide_right;
        integer rr, cc, w;
        begin
            for (rr = 0; rr < 4; rr = rr + 1) begin
                // read row
                for (cc = 0; cc < 4; cc = cc + 1)
                    row[cc] = board[rr*4 + cc];

                // clear newrow
                for (cc = 0; cc < 4; cc = cc + 1)
                    newrow[cc] = 12'd0;

                // pack non-zeros to the right (fill newrow from the end)
                w = 3;
                for (cc = 3; cc >= 0; cc = cc - 1) begin
                    if (row[cc] != 0) begin
                        newrow[w] = row[cc];
                        w = w - 1;
                    end
                end

                // write back
                for (cc = 0; cc < 4; cc = cc + 1)
                    board[rr*4 + cc] <= newrow[cc];
            end
        end
    endtask

    // Slide all tiles UP
    task slide_up;
        integer rr, cc, w;
        begin
            for (cc = 0; cc < 4; cc = cc + 1) begin
                // read column
                for (rr = 0; rr < 4; rr = rr + 1)
                    row[rr] = board[rr*4 + cc];

                // clear newrow
                for (rr = 0; rr < 4; rr = rr + 1)
                    newrow[rr] = 12'd0;

                // pack non-zeros upward
                w = 0;
                for (rr = 0; rr < 4; rr = rr + 1) begin
                    if (row[rr] != 0) begin
                        newrow[w] = row[rr];
                        w = w + 1;
                    end
                end

                // write back
                for (rr = 0; rr < 4; rr = rr + 1)
                    board[rr*4 + cc] <= newrow[rr];
            end
        end
    endtask

    // Slide all tiles DOWN
    task slide_down;
        integer rr, cc, w;
        begin
            for (cc = 0; cc < 4; cc = cc + 1) begin
                // read column
                for (rr = 0; rr < 4; rr = rr + 1)
                    row[rr] = board[rr*4 + cc];

                // clear newrow
                for (rr = 0; rr < 4; rr = rr + 1)
                    newrow[rr] = 12'd0;

                // pack non-zeros downward (fill newrow from the end)
                w = 3;
                for (rr = 3; rr >= 0; rr = rr - 1) begin
                    if (row[rr] != 0) begin
                        newrow[w] = row[rr];
                        w = w - 1;
                    end
                end

                // write back
                for (rr = 0; rr < 4; rr = rr + 1)
                    board[rr*4 + cc] <= newrow[rr];
            end
        end
    endtask

    // Merge for LEFT
    task merge_left;
        integer rr, cc, idx0, idx1;
        begin
            for (rr = 0; rr < 4; rr = rr + 1) begin
                for (cc = 0; cc < 3; cc = cc + 1) begin
                    idx0 = rr*4 + cc;
                    idx1 = rr*4 + (cc+1);
                    if (board[idx0] != 0 && board[idx0] == board[idx1]) begin
                        board[idx0] <= board[idx0] << 1; //double the value by moving 1 bit forward
                        board[idx1] <= 12'd0;
                        score       <= score + (board[idx0] << 1);
                    end
                end
            end
        end
    endtask

    // Merge for RIGHT
    task merge_right;
        integer rr, cc, idx0, idx1;
        begin
            for (rr = 0; rr < 4; rr = rr + 1) begin
                for (cc = 3; cc > 0; cc = cc - 1) begin
                    idx0 = rr*4 + cc;
                    idx1 = rr*4 + (cc-1);
                    if (board[idx0] != 0 && board[idx0] == board[idx1]) begin
                        board[idx0] <= board[idx0] << 1;
                        board[idx1] <= 12'd0;
                        score       <= score + (board[idx0] << 1);
                    end
                end
            end
        end
    endtask

    // Merge for UP
    task merge_up;
        integer rr, cc, idx0, idx1;
        begin
            for (cc = 0; cc < 4; cc = cc + 1) begin
                for (rr = 0; rr < 3; rr = rr + 1) begin
                    idx0 = rr*4 + cc;
                    idx1 = (rr+1)*4 + cc;
                    if (board[idx0] != 0 && board[idx0] == board[idx1]) begin
                        board[idx0] <= board[idx0] << 1;
                        board[idx1] <= 12'd0;
                        score       <= score + (board[idx0] << 1);
                    end
                end
            end
        end
    endtask

    // Merge for DOWN
    task merge_down;
        integer rr, cc, idx0, idx1;
        begin
            for (cc = 0; cc < 4; cc = cc + 1) begin
                for (rr = 3; rr > 0; rr = rr - 1) begin
                    idx0 = rr*4 + cc;
                    idx1 = (rr-1)*4 + cc;
                    if (board[idx0] != 0 && board[idx0] == board[idx1]) begin
                        board[idx0] <= board[idx0] << 1;
                        board[idx1] <= 12'd0;
                        score       <= score + (board[idx0] << 1);
                    end
                end
            end
        end
    endtask

    // ---------------------------------------------------------
    // Sequential actions per state
    // ---------------------------------------------------------
    reg placed; // used in SPAWN

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // already initialized in state register block
        end else begin
            case (state)

                // -----------------------------
                // INIT: simple starting board
                // -----------------------------
                S_INIT: begin
                    // one starting tile (you can improve)
                    board[0] <= 12'd2;
                    score    <= 16'd0;
                    game_state <= 2'd0;
                end

                // -----------------------------
                // WAIT_INPUT: latch dir + prev_board
                // -----------------------------
                S_WAIT_INPUT: begin
                    if (move_up || move_down || move_left || move_right) begin
                        if (move_up)        dir <= DIR_UP;
                        else if (move_down) dir <= DIR_DOWN;
                        else if (move_left) dir <= DIR_LEFT;
                        else                dir <= DIR_RIGHT;

                        for (i = 0; i < 16; i = i + 1)
                            prev_board[i] <= board[i];
                    end
                end

                // -----------------------------
                // First slide
                // -----------------------------
                S_SLIDE: begin
                    case (dir)
                        DIR_LEFT:  slide_left();
                        DIR_RIGHT: slide_right();
                        DIR_UP:    slide_up();
                        DIR_DOWN:  slide_down();
                    endcase
                end

                // -----------------------------
                // Merge
                // -----------------------------
                S_MERGE: begin
                    case (dir)
                        DIR_LEFT:  merge_left();
                        DIR_RIGHT: merge_right();
                        DIR_UP:    merge_up();
                        DIR_DOWN:  merge_down();
                    endcase
                end

                // -----------------------------
                // Second slide (close gaps)
                // -----------------------------
                S_SLIDE2: begin
                    case (dir)
                        DIR_LEFT:  slide_left();
                        DIR_RIGHT: slide_right();
                        DIR_UP:    slide_up();
                        DIR_DOWN:  slide_down();
                    endcase
                end

                // -----------------------------
                // CHECK: set game_state flags
                // -----------------------------
                S_CHECK: begin
                    if (has_2048_c)
                        game_state <= 2'd1;   // win
                    else if (!moves_left_c && board_changed_c)
                        game_state <= 2'd2;   // lose
                    else
                        game_state <= 2'd0;   // still playing
                end

                // -----------------------------
                // SPAWN: add a new tile (simple)
                // -----------------------------
                S_SPAWN: begin
                   placed = 1'b0;
                   // start from a random index and scan around the board once
                   for (i = 0; i < 16; i = i + 1) begin
                       idx = (rand_index + i) & 4'hF;   // wrap 0..15
                       if (!placed && board[idx] == 12'd0) begin
                       // 90% chance 2, 10% chance 4 (simple version)
                           if (rand_is_four && rnd[5])   // just using extra bits for “rarer”
                               board[idx] <= 12'd4;
                           else
                               board[idx] <= 12'd2;

                           placed = 1'b1;
                       end
                   end
                end


                // -----------------------------
                // END: nothing changes until reset
                // -----------------------------
                S_END: begin
                    // game_state already set; board frozen
                end

            endcase
        end
    end

endmodule
