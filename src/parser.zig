const std = @import("std");
const ArrayList = std.ArrayList;
const warn = std.debug.warn;

const Allocator = @import("std").mem.Allocator;
const attribute = @import("attribute.zig");
const Document = @import("document.zig").Document;
const Stack = @import("utils/stack.zig").Stack;
const Tag = @import("tag.zig").Tag;
const TagSet = @import("tag.zig").TagSet;
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;
const Tokenizer = @import("tokenizer.zig").Tokenizer;


const Scope = struct {
    tag: Tag,
    index: usize
};

const DocumentScopeStack = Stack(Scope);


const ParsingError = error {
    MalformedDocument
};


var DEFAULT_ATTRIBUTE_VALUE: []u8 = &"true";

const ParsingContext = struct {
    tags: ArrayList(Tag),
    parents: ArrayList(usize),
    texts: ArrayList([]u8),
    attributes: ArrayList(attribute.AttributeMap),

    document_scope_stack: DocumentScopeStack,
    self_closing_tags: TagSet,
    current_attribute_key: []u8,

    allocator: *Allocator,

    pub fn init(allocator: *Allocator) !ParsingContext {
        return ParsingContext {
            .tags = ArrayList(Tag).init(allocator),
            .parents = ArrayList(usize).init(allocator),
            .texts = ArrayList([]u8).init(allocator),
            .attributes = ArrayList(attribute.AttributeMap).init(allocator),
            .document_scope_stack = DocumentScopeStack.create(allocator),
            .self_closing_tags = try Tag.get_self_closing_tags(allocator),
            .current_attribute_key = "",
            .allocator = allocator
        };
    }

    pub fn deinit(self: *ParsingContext) void {
        self.document_scope_stack.deinit();
        self.self_closing_tags.deinit();
    }

    pub fn add_attribute_key(self: *ParsingContext, key: []u8) !void {
        var index = self.tags.count() - 1;
        _ = try self.attributes.toSlice()[index].put(key, DEFAULT_ATTRIBUTE_VALUE);
        self.current_attribute_key = key;
    }

    pub fn add_attribute_value(self: *ParsingContext, value: []u8) !void {
        var index = self.tags.count() - 1;
        _ = try self.attributes.toSlice()[index].put(self.current_attribute_key, value);
    }

    pub fn add_root_node(self: *ParsingContext) !void {
        return self.add_node(0, Tag.DocumentRoot, "");
    }

    pub fn add_scope(self: *ParsingContext, tag: Tag) !void {
        if (self.self_closing_tags.contains(tag)) {
            return;
        }
        var scope = Scope {.tag = tag, .index = self.tags.count()};
        try self.document_scope_stack.append(scope);
    }

    pub fn add_tag(self: *ParsingContext, tag: Tag) !void {
        var current_scope = self.get_last_scope();
        try self.add_scope(tag);
        return self.add_node(current_scope.index, tag, "");
    }

    pub fn add_text(self: *ParsingContext, text: []u8) !void {
        var current_scope = self.get_last_scope();
        return self.add_node(current_scope.index, Tag.Text, text);
    }

    pub fn get_document(self: *ParsingContext) Document {
        return Document {
            .tags = self.tags.toOwnedSlice(),
            .parents = self.parents.toOwnedSlice(),
            .texts = self.texts.toOwnedSlice(),
            .attributes = self.attributes.toOwnedSlice(),
            .allocator = self.allocator,
        };
    }

    pub fn get_last_scope(self: *ParsingContext) Scope {
        return self.document_scope_stack.last();
    }

    pub fn remove_last_scope(self: *ParsingContext) Scope {
        return self.document_scope_stack.pop();
    }

    fn add_node(self: *ParsingContext, parent: usize, tag: Tag, text: []u8) !void {
        try self.tags.append(tag);
        try self.parents.append(parent);
        try self.texts.append(text);
        try self.attributes.append(attribute.AttributeMap.init(self.allocator));
    }
};


pub const Parser = struct {
    tokenizer: Tokenizer,
    context: ParsingContext,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) !Parser {
        return Parser {
            .tokenizer = Tokenizer.init(allocator),
            .context = try ParsingContext.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.tokenizer.deinit();
        self.context.deinit();
    }

    pub fn parse(self: *Parser, html: []u8) !Document {
        try self.context.add_scope(Tag.DocumentRoot);
        try self.context.add_root_node();

        var tokens = try self.tokenizer.get_tokens(html);
        defer self.allocator.free(tokens);

        for (tokens) |*token| {
            switch(token.kind)  {
                TokenKind.Text => try self.handle_text_token(token.content),
                TokenKind.AttributeKey => try self.handle_attribute_key(token.content),
                TokenKind.AttributeValue => try self.handle_attribute_value(token.content),
                TokenKind.OpeningTag => try self.handle_opening_tag(token.content),
                TokenKind.ClosingTag => try self.handle_closing_tag(token.content),
                else => continue
            }
        }

        return self.context.get_document();
    }

    fn handle_opening_tag(self: *Parser, name: []u8) !void {
        var tag = Tag.from_name(name);
        try self.context.add_tag(tag);
    }

    fn handle_closing_tag(self: *Parser, name: []u8) !void {
        var tag = Tag.from_name(name);
        var current_scope = self.context.get_last_scope();

        if (current_scope.tag != tag) {
            return ParsingError.MalformedDocument;
        }
        _ = self.context.remove_last_scope();
    }

    fn handle_text_token(self: *Parser, text: []u8) !void {
        return self.context.add_text(text);
    }

    fn handle_attribute_key(self: *Parser, key: []u8) !void {
        try self.context.add_attribute_key(key);
    }

    fn handle_attribute_value(self: *Parser, value: []u8) !void {
        return try self.context.add_attribute_value(value);
    }
};


// ----------------- Tests -------------- //

// ----- Setup -----
const assert = std.debug.assert;
const bytes = @import("utils/bytes.zig");
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------

// ----- Test Parse -----

test "Parse tag." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div></div>");
    defer document.deinit();

    assert(document.tags[1] == Tag.Div);
    assert(document.parents[1] == 0);
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

    assert(bytes.equals(document.texts[1], ""));
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

    assert(document.tags[1] == Tag.Div);
    assert(document.parents[1] == 0);
    assert(document.tags[2] == Tag.P);
    assert(document.parents[2] == 1);
    assert(document.tags[3] == Tag.Div);
    assert(document.parents[3] == 1);
    assert(document.tags[4] == Tag.P);
    assert(document.parents[4] == 3);
}


test "Parse text." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div>Hello Hppy</div>");
    defer document.deinit();

    assert(document.tags[2] == Tag.Text);
    assert(document.parents[2] == 1);
    assert(bytes.equals(document.texts[2], "Hello Hppy"));
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

    assert(document.tags[1] == Tag.Div);
    assert(document.tags[2] == Tag.Text);
    assert(document.tags[3] == Tag.P);
    assert(document.tags[document.parents[2]] == Tag.Div);
    assert(document.tags[document.parents[3]] == Tag.Div);
}


test "Parse attributes - with key-only attribute." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div disabled >Hello</div>");
    defer document.deinit();

    assert(document.tags[1] == Tag.Div);
    assert(document.attributes[1].contains(&"disabled"));

    var disabled = document.attributes[1].get(&"disabled") orelse unreachable;
    assert(bytes.equals(disabled.value, "true"));
    assert(document.tags[2] == Tag.Text);
}


test "Parse attributes - Key-only arguments can be surrounded by any space characters." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div     disabled      >Hello</div>");
    defer document.deinit();

    assert(document.tags[1] == Tag.Div);
    assert(document.attributes[1].contains(&"disabled"));
    assert(document.tags[2] == Tag.Text);
}


test "Parse attributes - with key and value." {
    var parser = try Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<img width=\"500\">");
    defer document.deinit();

    assert(document.tags[1] == Tag.Img);

    var width = document.attributes[1].get(&"width") orelse unreachable;
    assert(bytes.equals(width.value, "500"));
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

    assert(document.tags[1] == Tag.Div);
    assert(document.tags[2] == Tag.Img);
    assert(document.tags[3] == Tag.P);
    assert(document.tags[document.parents[2]] == Tag.Div);
    assert(document.tags[document.parents[3]] == Tag.Div);
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
