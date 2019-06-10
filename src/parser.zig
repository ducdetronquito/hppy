const std = @import("std");
const warn = std.debug.warn;

const Allocator = @import("std").mem.Allocator;
const BytesList = @import("bytes.zig").BytesList;
const Document = @import("document.zig").Document;
const Tag = @import("tag.zig").Tag;
const TagList = @import("tag.zig").TagList;
const Token = @import("token.zig").Token;
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const TokenArray = @import("tokenizer.zig").TokenArray;


const ParentIndexList = std.ArrayList(usize);

pub fn parse(allocator: *Allocator, html: []u8) !Document {
    var tokenizer = Tokenizer.init(allocator);
    var document = Document.init(allocator);

    var parent_index_list = ParentIndexList.init(allocator);
    defer parent_index_list.deinit();

    try parent_index_list.append(0);

    var tag = Tag.Undefined;
    var text: []u8 = "";

    var tokens = try tokenizer.get_tokens(html);
    for (tokens.toSlice()) |*token| {
        if (token.is_closing_tag()) {
            var result = parent_index_list.pop();
            continue;
        }

        var parent_index = parent_index_list.at(parent_index_list.count() - 1);
        var content = token.content.toSlice();

        if (token.is_opening_tag()) {
            tag = Tag.from_name(content);
            text = "";
            try parent_index_list.append(document.tags.count());
            try document.tags.append(tag);
            try document.parents.append(parent_index);
            try document.texts.append(text);
            try document.attributes.append(BytesList.init(allocator));
        }
        else if (token.is_text()) {
            tag = Tag.Text;
            text = content;
            try document.tags.append(tag);
            try document.parents.append(parent_index);
            try document.texts.append(text);
        } else if (token.is_attribute()) {
            var previous_tag_index = document.tags.count() - 1;
            try document.attributes.toSlice()[previous_tag_index].append(content);
            continue;
        }
    }

    return document;
}

// ----------------- Tests -------------- //

// ----- Setup -----
const assert = std.debug.assert;
const Bytes = @import("bytes.zig").Bytes;
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------

// ----- Test Parse -----

test "Parse." {
    var document = try parse(&alloc, &"<div></div>");

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
}

test "Parse nested" {
    var document = try parse(&alloc, &"<div><p></p></div>");

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
    assert(tags[2] == Tag.P);
    assert(parents[2] == 1);
}


test "Parse text." {
    var document = try parse(&alloc, &"<div>Hello Hppy</div>");

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    var texts = document.texts.toSlice();
    assert(tags[2] == Tag.Text);
    assert(parents[2] == 1);
    assert(Bytes.equals(texts[2], "Hello Hppy"));
}

test "By default each tag as an empty string." {
    var document = try parse(&alloc, &"<div></div>");

    var texts = document.texts.toSlice();
    assert(Bytes.equals(texts[1], ""));
}

test "Text do not create a new hierarchy." {
    var html =
        \\<div>
        \\ Hello Hppy
        \\  <p></p>
        \\</div>
    ;
    var document = try parse(&alloc, &html);

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(tags[2] == Tag.Text);
    assert(tags[3] == Tag.P);
    assert(tags[parents[2]] == Tag.Div);
    assert(tags[parents[3]] == Tag.Div);
}


test "Parse multiple nested" {
    var html =
        \\<div>
        \\  <p>
        \\  </p>
        \\  <div>
        \\    <p></p>
        \\  </div>
        \\</div>
    ;
    var document = try parse(&alloc, &html);

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
    assert(tags[2] == Tag.P);
    assert(parents[2] == 1);
    assert(tags[3] == Tag.Div);
    assert(parents[3] == 1);
    assert(tags[4] == Tag.P);
    assert(parents[4] == 3);
}


test "Parse a key only attribute." {
    var document = try parse(&alloc, &"<div disabled >Hello</div>");

    var tags = document.tags.toSlice();
    var attributes = document.attributes.toSlice();
    assert(tags[1] == Tag.Div);
    assert(Bytes.equals(attributes[1].toSlice()[0], "disabled"));
    assert(tags[2] == Tag.Text);
}


test "Key only arguments can be surrounded by any space characters." {
    var document = try parse(&alloc, &"<div     disabled      >Hello</div>");

    var tags = document.tags.toSlice();
    var attributes = document.attributes.toSlice();
    assert(tags[1] == Tag.Div);
    assert(Bytes.equals(attributes[1].toSlice()[0], "disabled"));
    assert(tags[2] == Tag.Text);
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
