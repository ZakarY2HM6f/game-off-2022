const std = @import("std");
const Type = std.builtin.Type;

pub fn Iterator(comptime T: type) type {
    return struct {
        const Self = @This();

        next_fn: *const fn (iface: *Self) ?T,
        reset_fn: *const fn (iface: *Self) void,

        pub fn next(iface: *Self) ?T {
            return iface.next_fn(iface);
        }

        pub fn reset(iface: *Self) void {
            iface.reset_fn(iface);
        }
    };
}

pub fn SliceIterator(comptime T: type) type {
    return struct {
        const Self = @This();

        iterator: Iterator(T) = .{
            .next_fn = next,
            .reset_fn = reset,
        },

        slice: []const T,
        i: usize = 0,

        pub fn init(slice: []const T) Self {
            return Self{ .slice = slice };
        }

        fn next(iface: *Iterator(T)) ?T {
            const self = @fieldParentPtr(Self, "iterator", iface);
            if (self.i < self.slice.len) {
                const temp = self.slice[self.i];
                self.i += 1;
                return temp;
            }
            return null;
        }

        fn reset(iface: *Iterator(T)) void {
            const self = @fieldParentPtr(Self, "iterator", iface);
            self.i = 0;
        }
    };
}

pub fn ConcatIterator(comptime T: type, comptime I: type) type {
    return struct {
        const Self = @This();

        iterator: Iterator(T) = .{
            .next_fn = next,
            .reset_fn = reset,
        },

        iters: I,
        i: usize = 0,

        pub fn init(iters: I) Self {
            return Self{ .iters = iters };
        }

        fn next(iface: *Iterator(T)) ?T {
            const self = @fieldParentPtr(Self, "iterator", iface);
            while (self.i < @typeInfo(I).Struct.fields.len) {
                if (self.getIterator(self.i).next()) |item| {
                    return item;
                } else {
                    self.i += 1;
                }
            }
            return null;
        }

        fn reset(iface: *Iterator(T)) void {
            const self = @fieldParentPtr(Self, "iterator", iface);
            self.i = 0;
        }

        fn getIterator(self: *Self, i: usize) *Iterator(T) {
            comptime var j = 0;
            inline for (@typeInfo(I).Struct.fields) |field| {
                if (i == j) {
                    return &@field(self.iters, field.name).iterator;
                }
                j += 1;
            }
            unreachable;
        }
    };
}

pub fn InterfaceIterator(comptime T: type, comptime field: []const u8, comptime I: type) type {
    return struct {
        const Self = @This();

        iterator: Iterator(*I) = .{
            .next_fn = next,
            .reset_fn = reset,
        },

        iter: T,

        pub fn init(iter: T) Self {
            return Self{ .iter = iter };
        }

        fn next(iface: *Iterator(*I)) ?*I {
            const self = @fieldParentPtr(Self, "iterator", iface);
            if (self.iter.iterator.next()) |item| {
                return &@field(item, field);
            }
            return null;
        }

        fn reset(iface: *Iterator(*I)) void {
            const self = @fieldParentPtr(Self, "iterator", iface);
            self.iter.iterator.reset();
        }
    };
}
