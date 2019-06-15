const Allocator = @import("std").mem.Allocator;
const String = @import("utils/string.zig").String;


pub const TokenKind = enum {
    AttributeKey,
    AttributeValue,
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

    pub fn attribute_key(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.AttributeKey);
    }

    pub fn attribute_value(allocator: *Allocator) Token {
        return Token.init(allocator, TokenKind.AttributeValue);
    }
};


// ----------------- Tests -------------- //

// ----- Setup -----
const std = @import("std");
const assert = std.debug.assert;
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
// -----------------


test "Create an opening-tag token." {
    var token = Token.opening_tag(&alloc);

    assert(token.kind == TokenKind.OpeningTag);
}

test "Create an closing-tag token." {
    var token = Token.closing_tag(&alloc);

    assert(token.kind == TokenKind.ClosingTag);
}

test "Create an text token." {
    var token = Token.text(&alloc);

    assert(token.kind == TokenKind.Text);
}

test "Create an doctype token." {
    var token = Token.doctype(&alloc);

    assert(token.kind == TokenKind.Doctype);
}

test "Create an comment token." {
    var token = Token.comment(&alloc);

    assert(token.kind == TokenKind.Comment);
}

test "Create an attribute-key token." {
    var token = Token.attribute_key(&alloc);

    assert(token.kind == TokenKind.AttributeKey);
}

test "Create an attribute-value token." {
    var token = Token.attribute_value(&alloc);

    assert(token.kind == TokenKind.AttributeValue);
}

// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
