const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Iterator = @import("iterator.zig").Iterator;

pub fn ObjectPool(comptime T: type) type {
    return struct {
        const Self = @This();

        pool: ArrayList(ObjectPoolItem(T)),

        pub fn init(allocator: Allocator) Self {
            const pool = ArrayList(ObjectPoolItem(T)).init(allocator);
            return Self{ .pool = pool };
        }

        pub fn deinit(self: *Self) void {
            self.pool.deinit();
            self.* = undefined;
        }

        pub fn spawn(self: *Self, new_object: T) !void {
            var spawned = false;
            for (self.pool.items) |*object| {
                if (!object.enabled) {
                    object.enable(new_object);
                    spawned = true;
                    break;
                }
            }
            if (!spawned) {
                try self.pool.append(
                    ObjectPoolItem(T){
                        .enabled = true,
                        .object = new_object,
                    },
                );
            }
        }

        pub fn iter(self: *Self) ObjectPoolIterator(T) {
            return .{ .ptr = self };
        }
    };
}

pub fn ObjectPoolItem(comptime T: type) type {
    return struct {
        const Self = @This();

        enabled: bool = false,
        object: T,

        pub fn enable(self: *Self, object: T) void {
            self.enabled = true;
            self.object = object;
        }

        pub fn disable(self: *Self) void {
            self.enabled = false;
            self.object = undefined;
        }
    };
}

pub fn ObjectPoolIterator(comptime T: type) type {
    return struct {
        const Self = @This();

        iterator: Iterator(*T) = .{
            .next_fn = iteratorNext,
            .reset_fn = iteratorReset,
        },

        ptr: *ObjectPool(T),
        i: usize = 0,

        pub fn next(self: *Self) ?*T {
            while (self.i < self.ptr.pool.items.len) {
                const i = self.i;
                self.i += 1;
                if (self.ptr.pool.items[i].enabled) {
                    return &self.ptr.pool.items[i].object;
                }
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.i = 0;
        }

        fn iteratorNext(iface: *Iterator(*T)) ?*T {
            const self = @fieldParentPtr(Self, "iterator", iface);
            return self.next();
        }

        fn iteratorReset(iface: *Iterator(*T)) void {
            const self = @fieldParentPtr(Self, "iterator", iface);
            self.reset();
        }
    };
}
