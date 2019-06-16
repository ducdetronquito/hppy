const std = @import("std");
const ArrayList = std.ArrayList;
const warn = std.debug.warn;

const Allocator = @import("std").mem.Allocator;
const attribute = @import("attribute.zig");
const BytesList = @import("utils/bytes.zig").BytesList;
const Document = @import("document.zig").Document;
const ParentList = @import("hierarchy.zig").ParentList;
const Stack = @import("utils/stack.zig").Stack;
const Tag = @import("tag.zig").Tag;
const TagSet = @import("tag.zig").TagSet;
const TagList = @import("tag.zig").TagList;
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


var DEFAULT_ATTRIBUTE_VALUE: []u8 = &"true";

pub const Parser = struct {
    tokenizer: Tokenizer,
    document_scope_stack: DocumentScopeStack,
    self_closing_tags: TagSet,
    current_attribute_key: []u8,

    allocator: *Allocator,

    pub fn init(allocator: *Allocator) !Parser {
        return Parser {
            .tokenizer = Tokenizer.init(allocator),
            .document_scope_stack = DocumentScopeStack.create(allocator),
            .self_closing_tags = try Tag.get_self_closing_tags(allocator),
            .current_attribute_key = "",
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.document_scope_stack.deinit();
        self.tokenizer.deinit();
        self.self_closing_tags.deinit();
    }

    pub fn parse(self: *Parser, html: []u8) !Document {
        var tags = TagList.init(self.allocator);
        var parents = ParentList.init(self.allocator);
        var texts = BytesList.init(self.allocator);
        var attributes = attribute.AttributesList.init(self.allocator);
        var document = Document.init(&tags, &parents, &texts, &attributes);

        try self.add_document_root_to_document(&document);
        try self.document_scope_stack.append(Scope {.tag = Tag.DocumentRoot, .index = 0});

        var tokens = try self.tokenizer.get_tokens(html);
        for (tokens) |*token| {
            var content = token.content.toSlice();

            switch(token.kind)  {
                TokenKind.Text => try self.handle_text_token(&document, content),
                TokenKind.AttributeKey => try self.handle_attribute_key(&document, tags.count() -1, content),
                TokenKind.AttributeValue => try self.handle_attribute_value(&document, tags.count() -1, content),
                TokenKind.OpeningTag => try self.handle_opening_tag(&document, content),
                TokenKind.ClosingTag => try self.handle_closing_tag(content),
                else => continue
            }
        }

        return document;
    }

    fn handle_opening_tag(self: *Parser, document: *Document, name: []u8) !void {
        var tag = Tag.from_name(name);
        var current_scope = self.document_scope_stack.last();

        if (!self.self_closing_tags.contains(tag)) {
            try self.document_scope_stack.append(Scope { .tag = tag, .index = document.tags.count() });
        }
        try self.add_tag_to_document(document, current_scope.index, tag);
    }

    fn handle_closing_tag(self: *Parser, name: []u8) !void {
        var tag = Tag.from_name(name);
        var current_scope = self.document_scope_stack.last();

        if (current_scope.tag != tag) {
            return ParsingError.MalformedDocument;
        }
        _ = self.document_scope_stack.pop();
    }

    fn handle_text_token(self: *Parser, document: *Document, text: []u8) !void {
        var parent = self.document_scope_stack.last().index;
        return self.add_node_to_document(document, parent, Tag.Text, text);
    }

    fn handle_attribute_key(self: *Parser, document: *Document, parent: usize, key: []u8) !void {
        try self.add_attribute_to_node(document, parent, key, DEFAULT_ATTRIBUTE_VALUE);
        self.current_attribute_key = key;
    }

    fn handle_attribute_value(self: *Parser, document: *Document, parent: usize, value: []u8) !void {
        return try self.add_attribute_to_node(document, parent, self.current_attribute_key, value);
    }

    fn add_document_root_to_document(self: *Parser, document: *Document) !void {
        return self.add_node_to_document(document, 0, Tag.DocumentRoot, "");
    }

    fn add_tag_to_document(self: *Parser, document: *Document, parent: usize, tag: Tag) !void {
        return self.add_node_to_document(document, parent, tag, "");
    }

    fn add_text_to_document(self: *Parser, document: *Document, parent: usize, text: []u8) !void {
        return self.add_node_to_document(document, parent, Tag.Text, text);
    }

    fn add_node_to_document(self: *Parser, document: *Document, parent: usize, tag: Tag, text: []u8) !void {
        try document.tags.append(tag);
        try document.parents.append(parent);
        try document.texts.append(text);
        try document.attributes.append(attribute.AttributeMap.init(self.allocator));
    }

    fn add_attribute_to_node(self: *Parser, document: *Document, index: usize, key: []u8, value: []u8) !void {
        _ = try document.attributes.toSlice()[index].put(key, value);
    }

};


// ----------------- Tests -------------- //

// ----- Setup -----
const assert = std.debug.assert;
const Bytes = @import("utils/bytes.zig").Bytes;
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------

// ----- Test Parse -----

test "Parse tag." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div></div>");
    defer document.deinit();

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(parents[1] == 0);
}


test "Parse badly ordered closing tag returns an error." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();
    var value: ?Document = parser.parse(&"<div><p></div></p>") catch |err| switch(err) {
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
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div></div>");
    defer document.deinit();

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

    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&html);
    defer document.deinit();

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
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div>Hello Hppy</div>");
    defer document.deinit();

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
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&html);
    defer document.deinit();

    var tags = document.tags.toSlice();
    var parents = document.parents.toSlice();
    assert(tags[1] == Tag.Div);
    assert(tags[2] == Tag.Text);
    assert(tags[3] == Tag.P);
    assert(tags[parents[2]] == Tag.Div);
    assert(tags[parents[3]] == Tag.Div);
}


test "Parse attributes - with key-only attribute." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div disabled >Hello</div>");
    defer document.deinit();

    var tags = document.tags.toSlice();
    var attributes = document.attributes.toSlice();
    assert(tags[1] == Tag.Div);
    assert(attributes[1].contains(&"disabled"));

    var disabled = attributes[1].get(&"disabled") orelse unreachable;
    assert(Bytes.equals(disabled.value, "true"));
    assert(tags[2] == Tag.Text);
}


test "Parse attributes - Key-only arguments can be surrounded by any space characters." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div     disabled      >Hello</div>");
    defer document.deinit();

    var tags = document.tags.toSlice();
    var attributes = document.attributes.toSlice();
    assert(tags[1] == Tag.Div);
    assert(attributes[1].contains(&"disabled"));
    assert(tags[2] == Tag.Text);
}


test "Parse attributes - with key and value." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<img width=\"500\">");
    defer document.deinit();

    var tags = document.tags.toSlice();
    assert(tags[1] == Tag.Img);

    var attributes = document.attributes.toSlice();
    var width = attributes[1].get(&"width") orelse unreachable;
    assert(Bytes.equals(width.value, "500"));
}


test "Img tag do not create a new hierarchy." {
    var html =
        \\<div>
        \\  <img>
        \\  <p></p>
        \\</div>
    ;
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&html);
    defer document.deinit();

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
