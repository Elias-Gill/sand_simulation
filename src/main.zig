// raylib-zig (c) Nikolas Wipper 2023
const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: Allocator = gpa.allocator();

const screenWidth = 800;
const screenHeight = 450;

const particle_size = 4; // one particle of "sand" is a square of 4px by 4px.

const Grid = struct {
    // x-coordinates where the grid starts and ends in the screen
    start_x: i32,
    end_x: i32,

    // y-coordinates where the grid starts and ends in the screen
    start_y: i32,
    end_y: i32,

    // the actual array of points that composes the grid.
    width: i32,
    height: i32,
    grid: []bool, // single array of bools to be more "performant" (actually just for fun).

    // some rendering information
    grid_color: rl.Color = rl.Color.init(14, 14, 29, 20),

    pub fn init() Grid {
        // Grid initializacion.
        // Calculate some padding to not "overflow" the ui when drawing.
        const x_padding: i32 = screenWidth % particle_size;
        const y_padding: i32 = screenHeight % particle_size;

        // calculate the actual grid width and height using the calculated padding.
        const grid_width: i32 = screenWidth - x_padding;
        const grid_height: i32 = screenHeight - y_padding;

        // apply the padding and change the position of the grid drawing limits.
        var grid_start_x: i32 = 0;
        var grid_end_x: i32 = screenWidth;

        if (x_padding > 0) {
            if (x_padding % 2 == 0) {
                grid_start_x += x_padding / 2;
                grid_end_x -= x_padding / 2;
            } else {
                x_padding -= 1;
                grid_start_x += 1 + x_padding / 2;
                grid_end_x -= x_padding / 2;
            }
        }

        var grid_start_y: i32 = 0;
        var grid_end_y: i32 = screenHeight;

        if (y_padding > 0) {
            if (y_padding % 2 == 0) {
                grid_start_y += y_padding / 2;
                grid_end_y -= y_padding / 2;
            } else {
                y_padding -= 1;
                grid_start_y += 1 + y_padding / 2;
                grid_end_y -= y_padding / 2;
            }
        }

        const array = allocator.alloc(bool, grid_width * grid_height) catch {
            std.debug.panic("Failed to allocate memory", .{});
        };

        return Grid{
            .start_x = grid_end_x,
            .end_x = grid_end_x,
            .start_y = grid_end_y,
            .end_y = grid_end_y,
            .width = grid_width,
            .height = grid_height,
            .grid = array,
        };
    }

    pub fn deinit(self: Grid) void {
        allocator.free(self.grid);
    }
};

pub fn main() anyerror!void {
    // Gui initialization
    rl.initWindow(screenWidth, screenHeight, "Sand faling simulation");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    const grid = Grid.init();
    defer grid.deinit();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.clearBackground(rl.Color.ray_white);

        // TODO: main loop

        rl.endDrawing();
    }
}
