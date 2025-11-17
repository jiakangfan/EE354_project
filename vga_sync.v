module vga_sync (
    input  wire       clk,       // 25 MHz pixel clock
    input  wire       reset,
    output reg        hsync,
    output reg        vsync,
    output wire       video_on,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y
);
    // VGA 640x480 @ 60 Hz timing constants
    localparam H_VISIBLE     = 640;
    localparam H_FRONT_PORCH = 16;
    localparam H_SYNC_PULSE  = 96;
    localparam H_BACK_PORCH  = 48;
    localparam H_TOTAL       = H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; // 800

    localparam V_VISIBLE     = 480;
    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC_PULSE  = 2;
    localparam V_BACK_PORCH  = 33;
    localparam V_TOTAL       = V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; // 525

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Horizontal & vertical counters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // Generate sync pulses (active low)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            // HSYNC
            if (h_count >= H_VISIBLE + H_FRONT_PORCH &&
                h_count <  H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE)
                hsync <= 1'b0;
            else
                hsync <= 1'b1;

            // VSYNC
            if (v_count >= V_VISIBLE + V_FRONT_PORCH &&
                v_count <  V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE)
                vsync <= 1'b0;
            else
                vsync <= 1'b1;
        end
    end

    // Visible area flag
    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // Pixel coordinates in visible area
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule
