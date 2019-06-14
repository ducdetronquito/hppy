const Allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;


pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: ArrayList(T),

        pub fn create(allocator: *Allocator) Self {
            return Self {
                .items = ArrayList(T).init(allocator)
            };
        }

        pub fn deinit(self: *Self) void  {
            self.items.deinit();
        }

        pub fn append(self: *Self, item: T) !void {
            try self.items.append(item);
        }

        pub fn last(self: *Self) T {
            return self.items.at(self.items.count() - 1);
        }

        pub fn pop(self: *Self) T {
            return self.items.pop();
        }
    };
}
