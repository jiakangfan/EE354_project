
module game_logic
(
    input  wire        clk,
    input  wire        reset,
    input  wire        move_up,
    input  wire        move_down,
    input  wire        move_left,
    input  wire        move_right,
    output      [191:0] board_flat,  // 16 tiles * 12 bits
    output reg  [15:0]  score,
    output reg  [1:0]   game_state   // 0=playing, 1=win, 2=lose
);

    // 4x4 board: board[row*4 + col]
    reg [11:0] board      [0:15];   // registered board (state)
    reg [11:0] board_next [0:15];   // next board (computed in one move)

    // Pack board into flat bus for VGA
    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1)
        begin : pack_board
            assign board_flat[12*gi +: 12] = board[gi];
        end
    endgenerate

    // Random generator (same as your original)
    wire [9:0] rnd;
    lfsr_random rng (
        .clk   (clk),
        .reset (reset),
        .rnd   (rnd)
    );

    wire [3:0] rand_index   = rnd[3:0];  // 0..15
    wire       rand_is_four = rnd[4];    // choose 2 vs 4

    // Working arrays for lines
    reg [11:0] a[0:3];   // original / intermediate line
    reg [11:0] b[0:3];   // compressed / merged line

    // Shared integers / flags
    integer i, row_i, col_i, w;
    integer idx;

    reg        changed;       // did the board change this move?
    reg        has_2048;      // any tile == 2048?
    reg        moves_left;    // at least one legal move remains?
    reg        placed;        // used for spawn
    reg [15:0] score_add;     // accumulate score gained in this move

    // ------------------------------------------------------
    // Main sequential block
    // ------------------------------------------------------
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            // Clear board and set a single starting tile
            for (i = 0; i < 16; i = i + 1)
            begin
                board[i] <= 12'd0;
            end

            board[0]   <= 12'd2;   // top-left tile = 2 to start
            score      <= 16'd0;
            game_state <= 2'd0;    // playing
        end
        else
        begin
            // Only react when a move button is pressed
            if (move_up || move_down || move_left || move_right)
            begin
                // Start from current board
                for (i = 0; i < 16; i = i + 1)
                begin
                    board_next[i] = board[i];  // blocking: local working copy
                end

                changed   = 1'b0;
                score_add = 16'd0;

                // =======================================
                // 1) APPLY MOVE (slide + merge) into board_next
                // =======================================

                // ---- MOVE LEFT ----
                if (move_left)
                begin
                    for (row_i = 0; row_i < 4; row_i = row_i + 1)
                    begin
                        // Load row from board_next into a[]
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            a[col_i] = board_next[row_i*4 + col_i];
                        end

                        // First compress non-zeros to the left into b[]
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            b[col_i] = 12'd0;
                        end
                        w = 0;
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            if (a[col_i] != 12'd0)
                            begin
                                b[w] = a[col_i];
                                w    = w + 1;
                            end
                        end

                        // Merge equal neighbors in b[]
                        for (col_i = 0; col_i < 3; col_i = col_i + 1)
                        begin
                            if (b[col_i] != 12'd0 && b[col_i] == b[col_i+1])
                            begin
                                b[col_i]   = b[col_i] << 1;
                                score_add  = score_add + b[col_i];
                                b[col_i+1] = 12'd0;
                            end
                        end

                        // Compress again after merges, back into a[]
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            a[col_i] = 12'd0;
                        end
                        w = 0;
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            if (b[col_i] != 12'd0)
                            begin
                                a[w] = b[col_i];
                                w    = w + 1;
                            end
                        end

                        // Write back to board_next and detect change vs old board
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            if (board[row_i*4 + col_i] != a[col_i])
                                changed = 1'b1;
                            board_next[row_i*4 + col_i] = a[col_i];
                        end
                    end
                end

                // ---- MOVE RIGHT ----
                else if (move_right)
                begin
                    for (row_i = 0; row_i < 4; row_i = row_i + 1)
                    begin
                        // Load row from board_next reversed into a[]
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            a[col_i] = board_next[row_i*4 + (3 - col_i)];
                        end

                        // Compress non-zeros to the left into b[]
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            b[col_i] = 12'd0;
                        end
                        w = 0;
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            if (a[col_i] != 12'd0)
                            begin
                                b[w] = a[col_i];
                                w    = w + 1;
                            end
                        end

                        // Merge equal neighbors
                        for (col_i = 0; col_i < 3; col_i = col_i + 1)
                        begin
                            if (b[col_i] != 12'd0 && b[col_i] == b[col_i+1])
                            begin
                                b[col_i]   = b[col_i] << 1;
                                score_add  = score_add + b[col_i];
                                b[col_i+1] = 12'd0;
                            end
                        end

                        // Compress again
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            a[col_i] = 12'd0;
                        end
                        w = 0;
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            if (b[col_i] != 12'd0)
                            begin
                                a[w] = b[col_i];
                                w    = w + 1;
                            end
                        end

                        // Write back reversed into board_next and detect change
                        for (col_i = 0; col_i < 4; col_i = col_i + 1)
                        begin
                            if (board[row_i*4 + (3 - col_i)] != a[col_i])
                                changed = 1'b1;
                            board_next[row_i*4 + (3 - col_i)] = a[col_i];
                        end
                    end
                end

                // ---- MOVE UP ----
                else if (move_up)
                begin
                    for (col_i = 0; col_i < 4; col_i = col_i + 1)
                    begin
                        // Load column from board_next into a[]
                        a[0] = board_next[0*4 + col_i];
                        a[1] = board_next[1*4 + col_i];
                        a[2] = board_next[2*4 + col_i];
                        a[3] = board_next[3*4 + col_i];

                        // Compress non-zeros to the top
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            b[row_i] = 12'd0;
                        end
                        w = 0;
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            if (a[row_i] != 12'd0)
                            begin
                                b[w] = a[row_i];
                                w    = w + 1;
                            end
                        end

                        // Merge equal neighbors
                        for (row_i = 0; row_i < 3; row_i = row_i + 1)
                        begin
                            if (b[row_i] != 12'd0 && b[row_i] == b[row_i+1])
                            begin
                                b[row_i]   = b[row_i] << 1;
                                score_add  = score_add + b[row_i];
                                b[row_i+1] = 12'd0;
                            end
                        end

                        // Compress again
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            a[row_i] = 12'd0;
                        end
                        w = 0;
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            if (b[row_i] != 12'd0)
                            begin
                                a[w] = b[row_i];
                                w    = w + 1;
                            end
                        end

                        // Write back into board_next and detect change
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            if (board[row_i*4 + col_i] != a[row_i])
                                changed = 1'b1;
                            board_next[row_i*4 + col_i] = a[row_i];
                        end
                    end
                end

                // ---- MOVE DOWN ----
                else if (move_down)
                begin
                    for (col_i = 0; col_i < 4; col_i = col_i + 1)
                    begin
                        // Load column bottom→top from board_next into a[]
                        a[0] = board_next[3*4 + col_i];
                        a[1] = board_next[2*4 + col_i];
                        a[2] = board_next[1*4 + col_i];
                        a[3] = board_next[0*4 + col_i];

                        // Compress
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            b[row_i] = 12'd0;
                        end
                        w = 0;
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            if (a[row_i] != 12'd0)
                            begin
                                b[w] = a[row_i];
                                w    = w + 1;
                            end
                        end

                        // Merge
                        for (row_i = 0; row_i < 3; row_i = row_i + 1)
                        begin
                            if (b[row_i] != 12'd0 && b[row_i] == b[row_i+1])
                            begin
                                b[row_i]   = b[row_i] << 1;
                                score_add  = score_add + b[row_i];
                                b[row_i+1] = 12'd0;
                            end
                        end

                        // Compress again
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            a[row_i] = 12'd0;
                        end
                        w = 0;
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            if (b[row_i] != 12'd0)
                            begin
                                a[w] = b[row_i];
                                w    = w + 1;
                            end
                        end

                        // Write back reversed into board_next (toward bottom)
                        for (row_i = 0; row_i < 4; row_i = row_i + 1)
                        begin
                            if (board[(3-row_i)*4 + col_i] != a[row_i])
                                changed = 1'b1;
                            board_next[(3-row_i)*4 + col_i] = a[row_i];
                        end
                    end
                end


                has_2048   = 1'b0;
                moves_left = 1'b0;

                // Check for 2048 and empties
                for (i = 0; i < 16; i = i + 1)
                begin
                    if (board_next[i] == 12'd2048)
                        has_2048 = 1'b1;
                    if (board_next[i] == 12'd0)
                        moves_left = 1'b1;   // empty cell → at least one move
                end

                // Check neighbor merges
                for (row_i = 0; row_i < 4; row_i = row_i + 1)
                begin
                    for (col_i = 0; col_i < 4; col_i = col_i + 1)
                    begin
                        idx = row_i*4 + col_i;
                        if (col_i < 3 &&
                            board_next[idx] != 12'd0 &&
                            board_next[idx] == board_next[idx+1])
                            moves_left = 1'b1;
                        if (row_i < 3 &&
                            board_next[idx] != 12'd0 &&
                            board_next[idx] == board_next[idx+4])
                            moves_left = 1'b1;
                    end
                end

                // Update score
                score <= score + score_add;

                // Set game_state (before spawn)
                if (has_2048)
                    game_state <= 2'd1;   // win
                else if (!moves_left)
                    game_state <= 2'd2;   // lose
                else
                    game_state <= 2'd0;   // still playing


                if (changed && moves_left && !has_2048)
                begin
                    placed = 1'b0;
                    for (i = 0; i < 16; i = i + 1)
                    begin
                        idx = (rand_index + i) & 4'hF;  // wrap 0..15
                        if (!placed && board_next[idx] == 12'd0)
                        begin
                            if (rand_is_four && rnd[5])
                                board_next[idx] = 12'd4;
                            else
                                board_next[idx] = 12'd2;
                            placed = 1'b1;
                        end
                    end
                end


                for (i = 0; i < 16; i = i + 1)
                begin
                    board[i] <= board_next[i];
                end

            end
        end
    end

endmodule



