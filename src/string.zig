const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const BytesArray = std.ArrayList(u8);

pub const String = struct {
    bytes: BytesArray,

    pub fn init(allocator: *Allocator) String {
        var bytes = BytesArray.init(allocator);
        return String { .bytes = bytes };
    }

    fn deinit(self: *String) void {
        self.bytes.deinit();
    }
    
    fn push(self: *String, character: u8) void {
        return self.bytes.append(character) catch unreachable;
    }

    pub fn from(allocator: *Allocator, bytes: []u8) String {
        var _bytes = BytesArray.fromOwnedSlice(allocator, bytes);
        return String { .bytes = _bytes };
    }

    fn length(self: *String) usize {
        return self.bytes.len;
    }

    fn toSlice(self: *String) []u8 {
        return self.bytes.toSlice();
    }

    pub fn equals(self: *String, b: []const u8) bool {
        return mem.eql_slice_u8(self.bytes.toSlice(), b);
    }
};


// ----------------- Tests -------------- //

// ----- Setup -----
const assert = std.debug.assert;
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------

test "Create an empty String" {
    var name = String.init(&alloc);
    assert(name.bytes.len == 0);
}

test "Free a String" {
    var name = String.init(&alloc);
    defer name.deinit();
}

test "Push a character" {
    var name = String.init(&alloc);
    defer name.deinit();

    name.push('a');

    assert(name.bytes.len == 1);
    assert(name.bytes.items[0] == 'a');
}

test "From bytes array" {
    var content = []u8 {'a'};
    var name = String.from(&alloc, &content);
    defer name.deinit();

    assert(name.bytes.len == 1);
    assert(name.bytes.items[0] == 'a');
}

test "Len" {
    var content = "a";
    var name = String.from(&alloc, &content);
    defer name.deinit();

    assert(name.length() == 1);
}

test "ToSlice" {
    var content = "hellow hppy!";
    var name = String.from(&alloc, &content);
    defer name.deinit();

    assert(name.equals("hellow hppy!"));
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
