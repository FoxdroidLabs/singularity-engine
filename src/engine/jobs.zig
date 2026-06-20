const std = @import("std");
const Io = std.Io;

pub const Job = struct {
    func: *const fn (ctx: *anyopaque) void,
    ctx: *anyopaque,
};

pub const JobPool = struct {
    allocator: std.mem.Allocator,
    io: Io,
    threads: []std.Thread,
    queue: std.ArrayList(Job) = .empty,
    mutex: Io.Mutex = .init,
    cond: Io.Condition = .init,
    should_stop: bool = false,

    pub fn init(allocator: std.mem.Allocator, io: Io, worker_count: usize) !*JobPool {
        const pool = try allocator.create(JobPool);
        errdefer allocator.destroy(pool);

        pool.* = .{
            .allocator = allocator,
            .io = io,
            .threads = try allocator.alloc(std.Thread, worker_count),
        };
        errdefer allocator.free(pool.threads);

        for (pool.threads) |*t| {
            t.* = try std.Thread.spawn(.{}, workerLoop, .{pool});
        }
        return pool;
    }

    pub fn deinit(self: *JobPool) void {
        self.mutex.lockUncancelable(self.io);
        self.should_stop = true;
        self.mutex.unlock(self.io);
        self.cond.broadcast(self.io);

        for (self.threads) |t| t.join();

        self.allocator.free(self.threads);
        self.queue.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn submit(self: *JobPool, job: Job) !void {
        self.mutex.lockUncancelable(self.io);
        defer self.mutex.unlock(self.io);
        try self.queue.append(self.allocator, job);
        self.cond.signal(self.io);
    }

    fn workerLoop(self: *JobPool) void {
        while (true) {
            self.mutex.lockUncancelable(self.io);
            while (self.queue.items.len == 0 and !self.should_stop) {
                self.cond.waitUncancelable(self.io, &self.mutex);
            }
            if (self.should_stop and self.queue.items.len == 0) {
                self.mutex.unlock(self.io);
                return;
            }
            const job = self.queue.orderedRemove(0);
            self.mutex.unlock(self.io);
            job.func(job.ctx);
        }
    }
};
