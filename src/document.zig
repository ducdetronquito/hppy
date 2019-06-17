const std = @import("std");
const Allocator = std.mem.Allocator;
const Tag = @import("tag.zig").Tag;
const Parser = @import("parser.zig").Parser;
const AttributeMap = @import("attribute.zig").AttributeMap;


pub const Document = struct {
    tags: []Tag,
    parents: []usize,
    texts: [][]u8,
    attributes: []AttributeMap,
    allocator: *Allocator,

    pub fn deinit(self: *Document) void {
        self.allocator.free(self.tags);
        self.allocator.free(self.parents);
        self.allocator.free(self.texts);
        self.allocator.free(self.attributes);
    }

    pub fn from_string(allocator: *Allocator, html: []u8) !Document {
        var parser = Parser.init(allocator);
        defer parser.deinit();

        return try parser.parse(html);
    }
};


// ----------------- Tests -------------- //

// ----- Setup -----
const assert = std.debug.assert;
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------


test "Document.from_string" {
    var document = try Document.from_string(&alloc, &"<div></div>");
    defer document.deinit();

    assert(document.tags.len == 2);
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
