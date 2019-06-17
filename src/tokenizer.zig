const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const State = @import("state.zig").State;
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;
const assert = std.debug.assert;

const TokenArray = std.ArrayList(Token);

pub const Tokenizer = struct {
    state: State,
    token_has_been_found: bool,
    current_token_kind: TokenKind,
    current_token_content: std.ArrayList(u8),
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) Tokenizer {
        return Tokenizer {
            .state = State.SeekOpeningTag,
            .token_has_been_found = false,
            .current_token_kind = TokenKind.Doctype,
            .current_token_content = std.ArrayList(u8).init(allocator),
            .allocator = allocator
        };
    }

    pub fn deinit(self: *Tokenizer) void {
        self.current_token_content.deinit();
    }

    pub fn get_tokens(self: *Tokenizer, html: []u8) ![]Token {
        var tokens = TokenArray.init(self.allocator);
        for (html) |character| {
            try self.handle(character);
            if (!self.token_has_been_found) {
                continue;
            }

            var token = Token {
                .allocator = self.allocator,
                .kind = self.current_token_kind,
                .content = self.current_token_content.toOwnedSlice()
            };
            try tokens.append(token);
            self.token_has_been_found = false;
        }

        return tokens.toOwnedSlice();
    }

    fn handle(self: *Tokenizer, character: u8) !void {
        switch(self.state) {
            State.SeekOpeningTag => self.handle_seek_opening_tag(character),
            State.ReadClosingTagName => try self.handle_read_closing_tag_name(character),
            State.ReadTagName => try self.handle_read_tag_name(character),
            State.ReadOpeningTagName => try self.handle_read_opening_tag_name(character),
            State.ReadAttributes => try self.handle_read_attributes(character),
            State.ReadAttributeKey => try self.handle_read_attribute_key(character),
            State.ReadAttributeValueOpeningQuote => self.handle_read_attribute_value_opening_quote(character),
            State.ReadAttributeValue => try self.handle_read_attribute_value(character),
            State.ReadContent => try self.handle_read_content(character),
            State.ReadText => try self.handle_read_text(character),
            State.ReadOpeningCommentOrDoctype => try self.handle_read_opening_comment_or_doctype(character),
            State.ReadOpeningCommentDash => self.handle_read_opening_comment_dash(character),
            State.ReadCommentContent => try self.handle_read_comment_content(character),
            State.ReadClosingComment => self.handle_read_closing_comment(character),
            State.ReadClosingCommentDash => self.handle_read_closing_comment_dash(character),
            State.ReadDoctype => try self.handle_read_doctype(character),
            State.Done => return,
        }
    }

    fn handle_seek_opening_tag(self: *Tokenizer, character: u8) void {
        switch(character) {
            '<' => self.state = State.ReadTagName,
            else => return
        }
    }

    fn handle_read_tag_name(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '!' => self.state = State.ReadOpeningCommentOrDoctype,
            '/' => {
                self.current_token_kind = TokenKind.ClosingTag;
                self.state = State.ReadClosingTagName;
            },
            else => {
                self.current_token_kind = TokenKind.OpeningTag;
                try self.current_token_content.append(character);
                self.state = State.ReadOpeningTagName;
            }
        }
    }

    fn handle_read_opening_tag_name(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '>' => {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            ' ' => {
                self.token_has_been_found = true;
                self.state = State.ReadAttributes;
            },
            else => try self.current_token_content.append(character)
        }
    }

    fn handle_read_attributes(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '>' => {
                self.state = State.ReadContent;
            },
            ' ' => return,
            else => {
                self.current_token_kind = TokenKind.AttributeKey;
                try self.current_token_content.append(character);
                self.state = State.ReadAttributeKey;
            }
        }
    }

    fn handle_read_attribute_key(self: *Tokenizer, character: u8) !void {
        switch(character) {
            ' ' => {
                self.state = State.ReadAttributes;
                self.token_has_been_found = true;
            },
            '>' => {
                self.state = State.ReadContent;
                self.token_has_been_found = true;
            },
            '=' => {
                self.state = State.ReadAttributeValueOpeningQuote;
                self.token_has_been_found = true;
            },
            else => {
                try self.current_token_content.append(character);
            }
        }
    }

    fn handle_read_attribute_value_opening_quote(self: *Tokenizer, character: u8) void {
        switch(character) {
            '"' =>{
                self.current_token_kind = TokenKind.AttributeValue;
                self.state = State.ReadAttributeValue;
            },
            else => self.state = State.Done
        }
    }

    fn handle_read_attribute_value(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '"' => {
                self.state = State.ReadAttributes;
                self.token_has_been_found = true;
            },
            else => {
                try self.current_token_content.append(character);
            }
        }
    }

    fn handle_read_closing_tag_name(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '>' =>  {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            else => try self.current_token_content.append(character)
        }
    }

    fn handle_read_content(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '<' => self.state = State.ReadTagName,
            ' ' => return,
            '\n' => return,
            else => {
                self.current_token_kind = TokenKind.Text;
                try self.current_token_content.append(character);
                self.state = State.ReadText;
            }
        } 
    }

    fn handle_read_text(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '<' => {
                self.token_has_been_found = true;
                self.state = State.ReadTagName;
            },
            else => try self.current_token_content.append(character),
        }
    }

    fn handle_read_opening_comment_or_doctype(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '-' => self.state = State.ReadOpeningCommentDash,
            'D' => {
                try self.current_token_content.append(character);
                self.state = State.ReadDoctype;
            },
            else => return
        }
    }

    fn handle_read_opening_comment_dash(self: *Tokenizer, character: u8) void {
        switch(character) {
            '-' => {
                self.current_token_kind = TokenKind.Comment;
                self.state = State.ReadCommentContent;
            },
            else => self.state = State.Done,
        }
    }

    fn handle_read_comment_content(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '-' => self.state = State.ReadClosingComment,
            else => try self.current_token_content.append(character)
        }
    }

    fn handle_read_closing_comment(self: *Tokenizer, character: u8) void {
        switch(character) {
            '-' => self.state = State.ReadClosingCommentDash,
            else => self.state = State.ReadCommentContent
        }
    }

    fn handle_read_doctype(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '>' => {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            else => try self.current_token_content.append(character)
        }
    }

    fn handle_read_closing_comment_dash(self: *Tokenizer, character: u8) void {
        switch(character) {
            '>' => {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            else => self.state = State.ReadCommentContent
        }
    }
};

// ----------------- Tests -------------- //

// ----- Setup -----
const direct_allocator = std.heap.DirectAllocator.init();
var alloc = direct_allocator.allocator;
const bytes = @import("utils/bytes.zig");
// -----------------

// ----- Test Get Tokens -----

test "Can tokenize div with text" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = try tokenizer.get_tokens(&"<div>Hello Hppy</div>");
    assert(tokens.len == 3);
    assert(tokens[0].kind == TokenKind.OpeningTag);
    assert(bytes.equals(tokens[0].content, "div"));
    assert(tokens[1].kind == TokenKind.Text);
    assert(bytes.equals(tokens[1].content, "Hello Hppy"));
    assert(tokens[2].kind == TokenKind.ClosingTag);
    assert(bytes.equals(tokens[2].content, "div"));
}

test "Can tokenize doctype" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = try tokenizer.get_tokens(&"<!DOCTYPE html>");
    assert(tokens.len == 1);
    assert(tokens[0].kind == TokenKind.Doctype);
    assert(bytes.equals(tokens[0].content, "DOCTYPE html"));
}

test "Can tokenize comment" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = try tokenizer.get_tokens(&"<!-- Hello Hppy -->");
    assert(tokens.len == 1);
    assert(tokens[0].kind == TokenKind.Comment);
    assert(bytes.equals(tokens[0].content, " Hello Hppy "));
}


// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
