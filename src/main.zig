// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");

const screenWidth = 800;
const screenHeight = 450;

const grid_color = rl.Color.init(14, 14, 29, 20);

pub fn main() anyerror!void {
    // Initialization
    rl.initWindow(screenWidth, screenHeight, "Sand faling simulation");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.clearBackground(rl.Color.ray_white);

        draw_grid();

        rl.endDrawing();
    }
}

fn draw_grid() void {
    var i: i32 = 0;
    while (i < screenWidth) {
        rl.beginDrawing();
        rl.drawLine(i, 0, i, screenHeight, grid_color);
        i = i + 10;
    }

    i = 0;
    while (i < screenHeight) {
        rl.beginDrawing();
        rl.drawLine(0, i, screenWidth, i, grid_color);
        i = i + 10;
    }
}
