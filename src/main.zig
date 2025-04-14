const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: Allocator = gpa.allocator();

var prng: std.Random.DefaultPrng = undefined;
var rand: std.Random = undefined;

const screenWidth = 800;
const screenHeight = 450;

const particle_size = 2; // one particle of "sand" is a square of 4px by 4px.

const Grid = struct {
    // x-coordinates where the grid starts and ends in the screen
    start_x: usize,
    end_x: usize,

    // y-coordinates where the grid starts and ends in the screen
    start_y: usize,
    end_y: usize,

    // the actual array of points that composes the grid.
    columns: usize,
    rows: usize,
    grid: []bool, // single array of bools to be more "performant" (actually just for fun).

    // some rendering information
    cell_color: rl.Color = rl.Color.init(14, 14, 29, 120),

    pub fn init() Grid {
        // Grid initializacion.
        // Calculate some padding to not "overflow" the ui when drawing.
        var x_padding: usize = screenWidth % particle_size;
        var y_padding: usize = screenHeight % particle_size;

        // Calculate the actual amount of rows and columns for the grid, using the actual padding
        // and dividing by the size of a single particle.
        const rows: usize = (screenHeight - y_padding) / particle_size;
        const columns: usize = (screenWidth - x_padding) / particle_size;

        // apply the padding and change the position of the grid drawing limits.
        var grid_start_x: usize = 0;
        var grid_end_x: usize = screenWidth;

        if (x_padding % 2 == 0) {
            grid_start_x += x_padding / 2;
            grid_end_x -= x_padding / 2;
        } else { // unneven padding
            x_padding -= 1;
            grid_start_x += 1 + x_padding / 2;
            grid_end_x -= x_padding / 2;
        }

        var grid_start_y: usize = 0;
        var grid_end_y: usize = screenHeight;

        if (y_padding % 2 == 0) {
            grid_start_y += y_padding / 2;
            grid_end_y -= y_padding / 2;
        } else {
            y_padding -= 1;
            grid_start_y += 1 + y_padding / 2;
            grid_end_y -= y_padding / 2;
        }

        // initialize the array with all cells with default value as "false"
        const array = allocator.alloc(bool, rows * columns) catch {
            std.debug.panic("Failed to allocate memory", .{});
        };

        return Grid{
            .start_x = grid_start_x,
            .end_x = grid_end_x,
            .start_y = grid_start_y,
            .end_y = grid_end_y,
            .rows = rows,
            .columns = columns,
            .grid = array,
        };
    }

    pub fn deinit(self: Grid) void {
        allocator.free(self.grid);
    }

    pub fn draw_grid(self: Grid) void {
        for (self.grid, 0..) |occupied, index| {
            // Only draw occupied cells.
            if (occupied) {
                const row: usize = index / self.columns;
                const column: usize = index % self.columns;

                const y: i32 = @intCast(row * particle_size + self.start_y);
                const x: i32 = @intCast(column * particle_size + self.start_x);

                rl.drawRectangle(x, y, particle_size, particle_size, self.cell_color);
            }
        }
    }

    // Simulates the falling of the sand. (2 cells per milisecond)
    fn update(self: Grid, dt: f64) void {
        // Calculate how many simulation steps we need based on elapsed time
        const updates_per_second = 60; // Target simulation rate
        const target_dt = 1.0 / @as(f64, updates_per_second);
        var steps = @max(1, @as(usize, @intFromFloat(dt / target_dt + 0.5)));

        // Limit maximum steps to prevent spiral of death
        steps = @min(steps, 10);

        // Process multiple simulation steps if needed
        for (0..steps) |_| {
            self.updateStep();
        }
    }

    fn updateStep(self: Grid) void {
        // Process particles from bottom to top
        var i = self.grid.len;
        while (i > 0) {
            i -= 1;
            const curr_cell = i;

            // Skip empty cells
            if (!self.grid[curr_cell]) continue;

            const cell_below = curr_cell + self.columns;

            // Skip particles at bottom
            if (self.out_of_bounds(cell_below)) continue;

            // Fall down with probability based on time step
            if (!self.grid[cell_below]) {
                // randomly decide to stay on this cell or fall down (this gives a more
                // pleasing effect)
                if (rand.intRangeAtMost(usize, 0, 100) > 87) {
                    continue;
                }
                self.moveCell(curr_cell, cell_below);
                continue;
            }

            // Side movement checks
            const right_available = !self.out_of_bounds(cell_below + 1) and !self.grid[cell_below + 1];
            const left_available = !self.out_of_bounds(cell_below - 1) and !self.grid[cell_below - 1];

            if (right_available and left_available) {
                if (rand.boolean()) {
                    self.moveCell(curr_cell, cell_below - 1);
                } else {
                    self.moveCell(curr_cell, cell_below + 1);
                }
            } else if (right_available) {
                self.moveCell(curr_cell, cell_below + 1);
            } else if (left_available) {
                self.moveCell(curr_cell, cell_below - 1);
            }
        }
    }

    fn moveCell(self: Grid, from: usize, to: usize) void {
        self.grid[from] = false;
        self.grid[to] = true;
    }

    fn out_of_bounds(self: Grid, i: usize) bool {
        return i >= self.grid.len or i < 0;
    }

    // Add a random block of sand inside the simulation
    fn generate_sand(self: Grid, left: usize, right: usize) void {
        const position = rand.intRangeAtMost(usize, left, right);
        const random = rand.intRangeAtMost(usize, 0, 100);

        if (random > 30 and random < 60) {
            // generate a block of sand
            self.grid[position] = true;
            self.grid[position + 1] = true;
            self.grid[position + 2] = true;
            self.grid[position + 3] = true;
            self.grid[position + 4] = true;
            self.grid[position + 5] = true;
            self.grid[position + 6] = true;

            self.grid[position + self.columns] = true;
            self.grid[position + 1 + self.columns] = true;
            self.grid[position + 2 + self.columns] = true;
            self.grid[position + 3 + self.columns] = true;
            self.grid[position + 4 + self.columns] = true;
            self.grid[position + 5 + self.columns] = true;
            self.grid[position + 6 + self.columns] = true;
        }
    }
};

pub fn main() anyerror!void {
    // Initialize a random numbers generator
    prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();

    // -----------------------------------------------------------------------
    // Gui initialization

    rl.initWindow(screenWidth, screenHeight, "Sand faling simulation");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    const grid = Grid.init();
    defer grid.deinit();

    // Has the delta-time elapsed since the last simulation "tick".
    var last_tick: f64 = 0;

    grid.grid[0] = true;
    grid.grid[2] = true;
    grid.grid[85] = true;

    // -----------------------------------------------------------------------
    // Main game loop

    while (!rl.windowShouldClose()) {
        const curr_time: f64 = rl.getTime();
        const lapsed_time: f64 = curr_time - last_tick;

        // update the grid on every milisecond
        if (lapsed_time > 0.001) {
            last_tick = curr_time;

            // Randomly generate a bunch of sand
            grid.generate_sand(2 * (grid.columns / 3) - 10, 2 * (grid.columns / 3) + 10);
            grid.generate_sand(grid.columns / 5 - 10, grid.columns / 5 + 10);

            // Update the sand grid
            grid.update(lapsed_time);
        }

        // Draw the updated frame
        rl.clearBackground(rl.Color.ray_white);
        rl.beginDrawing();
        grid.draw_grid();
        rl.endDrawing();
    }
}
