const Allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;


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
    content: []u8,
    allocator: *Allocator,

    fn init(allocator: *Allocator, kind: TokenKind, content: []u8) Token {
        return Token {
            .kind = kind,
            .content = content,
            .allocator = allocator,
        };
    }
};
