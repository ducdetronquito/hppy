const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const BytesList = @import("utils/bytes.zig").BytesList;
const Tag = @import("tag.zig").Tag;
const TagList = @import("tag.zig").TagList;
const parser = @import("parser.zig");
const ParentList = ArrayList(usize);
const AttributeMap = @import("attributes.zig").AttributeMap;


const AttributesList = ArrayList(AttributeMap);


pub const Document = struct {
    tags: TagList,
    parents: ParentList,
    texts: BytesList,
    attributes: AttributesList,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) Document {
        var tags = TagList.init(allocator);
        tags.append(Tag.DocumentRoot) catch unreachable;

        var parents = ParentList.init(allocator);
        parents.append(0) catch unreachable;

        var texts = BytesList.init(allocator);
        texts.append("") catch unreachable;

        var attributes = AttributesList.init(allocator);
        attributes.append(AttributeMap.init(allocator)) catch unreachable;

        return Document {
            .allocator = allocator,
            .tags = tags,
            .parents = parents,
            .texts = texts,
            .attributes = attributes,
        };
    }

    pub fn from_string(allocator: *Allocator, html: []u8) !Document {
        return try parser.parse(allocator, html);
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

    assert(document.tags.toSlice().len == 2);
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
