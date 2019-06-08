const Allocator = @import("std").mem.Allocator;
const String = @import("string.zig").String;


pub const TokenKind = enum {
    Attribute,
    Doctype,
    ClosingTag,
    Comment,
    OpeningTag,
    Text,
};

pub const Token = struct {
    kind: TokenKind,
    content: String,

    fn init(allocator: *Allocator, kind: TokenKind) Token {
        return Token {
            .kind = kind,
            .content = String.init(allocator)
        };
    }

    pub fn opening_tag(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.OpeningTag);
    }

    pub fn closing_tag(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.ClosingTag);
    }

    pub fn text(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.Text);
    }

    pub fn doctype(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.Doctype);
    }

    pub fn comment(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.Comment);
    }

    pub fn attribute(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.Attribute);
    }

    fn is_opening_tag(self: Token) bool {
        return self.kind == TokenKind.OpeningTag;
    }

    fn is_closing_tag(self: Token) bool {
        return self.kind == TokenKind.ClosingTag;
    }

    fn is_text(self: Token) bool {
        return self.kind == TokenKind.Text;
    }

    fn is_doctype(self: Token) bool {
        return self.kind == TokenKind.Doctype;
    }

    fn is_comment(self: Token) bool {
        return self.kind == TokenKind.Comment;
    }

    fn is_attribute(self: Token) bool {
        return self.kind == TokenKind.Attribute;
    }
};


// ----------------- Tests -------------- //

// ----- Setup -----
const std = @import("std");
const assert = std.debug.assert;
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------


test "Create an opening Tag" {
    var token = Token.opening_tag(&alloc);

    assert(token.is_opening_tag() == true);
}

test "Create an closing Tag" {
    var token = Token.closing_tag(&alloc);

    assert(token.is_closing_tag() == true);
}

test "Create an text Tag" {
    var token = Token.text(&alloc);

    assert(token.is_text() == true);
}

test "Create an Doctype Tag" {
    var token = Token.doctype(&alloc);

    assert(token.is_doctype() == true);
}

test "Create an Comment Tag" {
    var token = Token.comment(&alloc);

    assert(token.is_comment() == true);
}

test "Create an Attribute Tag" {
    var token = Token.attribute(&alloc);

    assert(token.is_attribute() == true);
}

test "Token is an opening tag" {
    var token = Token.init(&alloc, TokenKind.OpeningTag);

    assert(token.is_opening_tag() == true);
}

test "Token is a closing tag" {
    var token = Token.init(&alloc, TokenKind.ClosingTag);

    assert(token.is_closing_tag() == true);
}

test "Token is a text" {
    var token = Token.init(&alloc, TokenKind.Text);

    assert(token.is_text() == true);
}

test "Token is a doctype" {
    var token = Token.init(&alloc, TokenKind.Doctype);

    assert(token.is_doctype() == true);
}

test "Token is comment" {
    var token = Token.init(&alloc, TokenKind.Comment);

    assert(token.is_comment() == true);
}

test "Token is an attribute" {
    var token = Token.init(&alloc, TokenKind.Attribute);

    assert(token.is_attribute() == true);
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
