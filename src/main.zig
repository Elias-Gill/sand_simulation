const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: Allocator = gpa.allocator();

var prng: std.rand.DefaultPrng = undefined;
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

    // Simulates the falling of the sand.
    fn update(self: Grid) void {
        // Start updating the particles one at a time from bottom up.
        for (1..self.grid.len + 1) |i| {
            const cell = self.grid.len - i;
            const bellow = cell + self.columns;

            // ignore empty cells
            if (!self.grid[cell]) {
                continue;
            }

            // Ignore the bottom ones.
            if (self.out_of_bounds(bellow)) {
                continue;
            }

            // If the cell bellow is empty then fall inmediatlly
            if (!self.grid[bellow]) {
                // randomly decide to stay on this cell or fall down
                if (rand.intRangeAtMost(usize, 0, 100) > 87) {
                    continue;
                }

                self.grid[cell] = false;
                self.grid[bellow] = true;
                continue;
            }

            // if the cell bellow is endeed ocupied, then check bellow to the right
            if (!self.out_of_bounds(bellow + 1) and !self.grid[bellow + 1]) {

                // Check to the left. If both sides are empty then randomly fall to one side.
                if (!self.out_of_bounds(bellow - 1) and !self.grid[bellow - 1]) {
                    const left = rand.boolean();
                    if (left) {
                        self.grid[cell] = false;
                        self.grid[bellow - 1] = true;
                        continue;
                    }
                }

                // or fall to the right
                self.grid[cell] = false;
                self.grid[bellow + 1] = true;
                continue;
            }

            // fall to the left
            if (!self.out_of_bounds(bellow - 1) and !self.grid[bellow - 1]) {
                self.grid[cell] = false;
                self.grid[bellow - 1] = true;
            }

            // or ignore this cell
        }
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
    prng = std.rand.DefaultPrng.init(blk: {
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
        // Randomly generate a bunch of sand every milisecond
        const curr_time: f64 = rl.getTime();
        if (curr_time - last_tick > 0.001) {
            last_tick = curr_time;

            grid.generate_sand(2 * (grid.columns / 3) - 10, 2 * (grid.columns / 3) + 10);
            grid.generate_sand(grid.columns / 5 - 10, grid.columns / 5 + 10);
        }

        grid.update();

        rl.clearBackground(rl.Color.ray_white);
        rl.beginDrawing();

        grid.draw_grid();

        rl.endDrawing();
    }
}
