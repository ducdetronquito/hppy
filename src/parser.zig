const std = @import("std");
const warn = std.debug.warn;

const Allocator = @import("std").mem.Allocator;
const Document = @import("document.zig").Document;
const Tag = @import("tag.zig").Tag;
const TagList = @import("tag.zig").TagList;
const Token = @import("token.zig").Token;
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const TokenArray = @import("tokenizer.zig").TokenArray;


const ParentIndexList = std.ArrayList(usize);

pub fn parse(allocator: *Allocator, html: []u8) Document {
    var tokenizer = Tokenizer.init(allocator);
    var document = Document.init(allocator);

    var parent_index_list = ParentIndexList.init(allocator);
    defer parent_index_list.deinit();

    parent_index_list.append(0) catch unreachable;

    var tag = Tag.Undefined;
    var text: []u8 = "";

    for (tokenizer.get_tokens(html).toSlice()) |*token| {
        if (token.is_closing_tag()) {
            var result = parent_index_list.pop();
            continue;
        }

        var parent_index = parent_index_list.at(parent_index_list.count() - 1);
        var content = token.content.toSlice();

        if (token.is_opening_tag()) {
            tag = Tag.from_name(content);
            text = "";
            parent_index_list.append(document.tags.count()) catch unreachable;
        }
        else if (token.is_text()) {
            tag = Tag.Text;
            text = content;
        } else {
            continue;
        }

        document.tags.append(tag) catch unreachable;
        document.parents.append(parent_index) catch unreachable;
        document.texts.append(text) catch unreachable;
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
    var result = parse(&alloc, &"<div></div>");

    var tags = result.tags.toSlice();
    var parents = result.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
}

test "Parse nested" {
    var result = parse(&alloc, &"<div><p></p></div>");

    var tags = result.tags.toSlice();
    var parents = result.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
    assert(tags[2] == Tag.P);
    assert(parents[2] == 1);
}


test "Parse text." {
    var result = parse(&alloc, &"<div>Hello Hppy</div>");

    var tags = result.tags.toSlice();
    var parents = result.parents.toSlice();
    var texts = result.texts.toSlice();
    assert(tags[2] == Tag.Text);
    assert(parents[2] == 1);
    assert(Bytes.equals(texts[2], "Hello Hppy"));
}

test "By default each tag as an empty string." {
    var result = parse(&alloc, &"<div></div>");

    var texts = result.texts.toSlice();
    assert(Bytes.equals(texts[1], ""));
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
    var result = parse(&alloc, &html);

    var tags = result.tags.toSlice();
    var parents = result.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
    assert(tags[2] == Tag.P);
    assert(parents[2] == 1);
    assert(tags[3] == Tag.Div);
    assert(parents[3] == 1);
    assert(tags[4] == Tag.P);
    assert(parents[4] == 3);
}


// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
