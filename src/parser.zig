const std = @import("std");
const ArrayList = std.ArrayList;
const warn = std.debug.warn;

const Allocator = @import("std").mem.Allocator;
const AttributeMap = @import("attributes.zig").AttributeMap;
const Document = @import("document.zig").Document;
const Stack = @import("stack.zig").Stack;
const Tag = @import("tag.zig").Tag;
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const TokenArray = @import("tokenizer.zig").TokenArray;


const Scope = struct {
    tag: Tag,
    index: usize
};

const DocumentScopeStack = Stack(Scope);


const ParsingError = error {
    MalformedDocument
};


pub fn parse(allocator: *Allocator, html: []u8) !Document {
    var tokenizer = Tokenizer.init(allocator);

    var document_scope_stack = DocumentScopeStack.create(allocator);
    defer document_scope_stack.deinit();
    try document_scope_stack.append(Scope {.tag = Tag.DocumentRoot, .index = 0});

    var tag = Tag.Undefined;
    var text: []u8 = "";

    var self_closing_tags = try Tag.get_self_closing_tags(allocator);
    defer self_closing_tags.deinit();

    var document = Document.init(allocator);
    var tokens = try tokenizer.get_tokens(html);

    for (tokens.toSlice()) |*token| {

        var current_scope = document_scope_stack.last();
        var content = token.content.toSlice();

        switch(token.kind)  {
            TokenKind.OpeningTag => {
                tag = Tag.from_name(content);

                if (!self_closing_tags.contains(tag)) {
                    try document_scope_stack.append(
                        Scope {
                            .tag = tag,
                            .index = document.tags.count()
                        }
                    );
                }
                try add_tag_to_document(allocator, &document, current_scope.index, tag);
            },
            TokenKind.ClosingTag => {
                tag = Tag.from_name(content);
                if (current_scope.tag != tag) {
                    return ParsingError.MalformedDocument;
                }
                _ = document_scope_stack.pop();
                continue;
            },
            TokenKind.Text => try add_text_to_document(allocator, &document, current_scope.index, content),
            TokenKind.Attribute => try add_attribute_to_node(&document, current_scope.index, content),
            else => continue
        }
    }

    return document;
}


fn add_tag_to_document(allocator: *Allocator, document: *Document, parent: usize, tag: Tag) !void {
    return add_node_to_document(allocator, document, parent, tag, "");
}


fn add_text_to_document(allocator: *Allocator, document: *Document, parent: usize, text: []u8) !void {
    return add_node_to_document(allocator, document, parent, Tag.Text, text);
}

fn add_node_to_document(allocator: *Allocator, document: *Document, parent: usize, tag: Tag, text: []u8) !void {
    try document.tags.append(tag);
    try document.parents.append(parent);
    try document.texts.append(text);
    try document.attributes.append(AttributeMap.init(allocator));
}

fn add_attribute_to_node(document: *Document, index: usize, content: []u8) !void {
    _ = try document.attributes.toSlice()[index].put(content, & "true");
}

// ----------------- Tests -------------- //

// ----- Setup -----
const assert = std.debug.assert;
const Bytes = @import("bytes.zig").Bytes;
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------

// ----- Test Parse -----

test "Parse tag." {
    var document = try parse(&alloc, &"<div></div>");

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
}


test "Parse badly ordered closing tag returns an error." {
    var value: ?Document = parse(&alloc, &"<div><p></div></p>") catch |err| switch(err) {
        ParsingError.MalformedDocument => {
            return {};
        },
        else => {
            unreachable;
        }
    };

    assert(false);
}

test "Parse tag - By default each tag as an empty string." {
    var document = try parse(&alloc, &"<div></div>");

    var texts = document.texts.toSlice();
    assert(Bytes.equals(texts[1], ""));
}

test "Parse tag - with multiple nested tags." {
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


test "Parse text." {
    var document = try parse(&alloc, &"<div>Hello Hppy</div>");

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    var texts = document.texts.toSlice();
    assert(tags[2] == Tag.Text);
    assert(parents[2] == 1);
    assert(Bytes.equals(texts[2], "Hello Hppy"));
}

test "Parse text - Do not create a new hierarchy." {
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


test "Parse attributes - with key-only attribute." {
    var document = try parse(&alloc, &"<div disabled >Hello</div>");

    var tags = document.tags.toSlice();
    var attributes = document.attributes.toSlice();
    assert(tags[1] == Tag.Div);
    assert(attributes[1].contains(&"disabled"));

    var attribute = attributes[1].get(&"disabled") orelse unreachable;
    assert(Bytes.equals(attribute.value, "true"));
    assert(tags[2] == Tag.Text);
}


test "Parse attributes - Key-only arguments can be surrounded by any space characters." {
    var document = try parse(&alloc, &"<div     disabled      >Hello</div>");

    var tags = document.tags.toSlice();
    var attributes = document.attributes.toSlice();
    assert(tags[1] == Tag.Div);
    assert(attributes[1].contains(&"disabled"));
    assert(tags[2] == Tag.Text);
}


test "Img tag do not create a new hierarchy." {
    var html =
        \\<div>
        \\  <img>
        \\  <p></p>
        \\</div>
    ;
    var document = try parse(&alloc, &html);

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(tags[2] == Tag.Img);
    assert(tags[3] == Tag.P);
    assert(tags[parents[2]] == Tag.Div);
    assert(tags[parents[3]] == Tag.Div);
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
