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

    pub fn add_document_root_to_document(self: *ParsingContext) !void {
        return self.add_node_to_document(0, Tag.DocumentRoot, "");
    }

    pub fn add_tag_to_document(self: *ParsingContext, parent: usize, tag: Tag) !void {
        return self.add_node_to_document(parent, tag, "");
    }

    pub fn add_text_to_document(self: *ParsingContext, parent: usize, text: []u8) !void {
        return self.add_node_to_document(parent, Tag.Text, text);
    }
    pub fn add_scope(self: *ParsingContext, scope: Scope) !void {
        try self.document_scope_stack.append(scope);
    }

    fn add_node_to_document(self: *ParsingContext, parent: usize, tag: Tag, text: []u8) !void {
        try self.tags.append(tag);
        try self.parents.append(parent);
        try self.texts.append(text);
        try self.attributes.append(attribute.AttributeMap.init(self.allocator));
    }

    pub fn add_attribute_to_node(self: *ParsingContext, index: usize, key: []u8, value: []u8) !void {
        _ = try self.attributes.toSlice()[index].put(key, value);
    }
};


pub const Parser = struct {
    tokenizer: Tokenizer,

    allocator: *Allocator,

    pub fn init(allocator: *Allocator) Parser {
        return Parser {
            .tokenizer = Tokenizer.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.tokenizer.deinit();
    }

    pub fn parse(self: *Parser, html: []u8) !Document {
        var parsing_context = try ParsingContext.init(self.allocator);
        defer parsing_context.deinit();

        try parsing_context.add_document_root_to_document();
        try parsing_context.add_scope(Scope {.tag = Tag.DocumentRoot, .index = 0});

        var tokens = try self.tokenizer.get_tokens(html);
        defer self.allocator.free(tokens);

        for (tokens) |*token| {
            switch(token.kind)  {
                TokenKind.Text => try self.handle_text_token(&parsing_context, token.content),
                TokenKind.AttributeKey => try self.handle_attribute_key(&parsing_context, token.content),
                TokenKind.AttributeValue => try self.handle_attribute_value(&parsing_context, token.content),
                TokenKind.OpeningTag => try self.handle_opening_tag(&parsing_context, token.content),
                TokenKind.ClosingTag => try self.handle_closing_tag(&parsing_context, token.content),
                else => continue
            }
        }

        var document  = Document {
            .tags = parsing_context.tags.toOwnedSlice(),
            .parents = parsing_context.parents.toOwnedSlice(),
            .texts = parsing_context.texts.toOwnedSlice(),
            .attributes = parsing_context.attributes.toOwnedSlice(),
            .allocator = self.allocator,
        };

        return document;
    }

    fn handle_opening_tag(self: *Parser, parsing_context: *ParsingContext, name: []u8) !void {
        var tag = Tag.from_name(name);
        var current_scope = parsing_context.document_scope_stack.last();

        if (!parsing_context.self_closing_tags.contains(tag)) {
            try parsing_context.document_scope_stack.append(Scope { .tag = tag, .index = parsing_context.tags.count() });
        }
        try parsing_context.add_tag_to_document(current_scope.index, tag);
    }

    fn handle_closing_tag(self: *Parser, parsing_context: *ParsingContext, name: []u8) !void {
        var tag = Tag.from_name(name);
        var current_scope = parsing_context.document_scope_stack.last();

        if (current_scope.tag != tag) {
            return ParsingError.MalformedDocument;
        }
        _ = parsing_context.document_scope_stack.pop();
    }

    fn handle_text_token(self: *Parser, parsing_context: *ParsingContext, text: []u8) !void {
        var parent = parsing_context.document_scope_stack.last().index;
        return parsing_context.add_node_to_document(parent, Tag.Text, text);
    }

    fn handle_attribute_key(self: *Parser, parsing_context: *ParsingContext, key: []u8) !void {
        try parsing_context.add_attribute_to_node(parsing_context.tags.count() - 1, key, DEFAULT_ATTRIBUTE_VALUE);
        parsing_context.current_attribute_key = key;
    }

    fn handle_attribute_value(self: *Parser, parsing_context: *ParsingContext, value: []u8) !void {
        return try parsing_context.add_attribute_to_node(parsing_context.tags.count() - 1, parsing_context.current_attribute_key, value);
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
    var parser = Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div></div>");
    defer document.deinit();

    assert(document.tags[1] == Tag.Div);
    assert(document.parents[1] == 0);
}


test "Parse badly ordered closing tag returns an error." {
    var parser = Parser.init(&alloc);
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
    var parser = Parser.init(&alloc);
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

    var parser = Parser.init(&alloc);
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
    var parser = Parser.init(&alloc);
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
    var parser = Parser.init(&alloc);
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
    var parser = Parser.init(&alloc);
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
    var parser = Parser.init(&alloc);
    defer parser.deinit();

    var document = try parser.parse(&"<div     disabled      >Hello</div>");
    defer document.deinit();

    assert(document.tags[1] == Tag.Div);
    assert(document.attributes[1].contains(&"disabled"));
    assert(document.tags[2] == Tag.Text);
}


test "Parse attributes - with key and value." {
    var parser = Parser.init(&alloc);
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
    var parser = Parser.init(&alloc);
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
