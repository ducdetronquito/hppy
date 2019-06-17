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
    token: Token,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) Tokenizer {
        return Tokenizer {
            .state = State.SeekOpeningTag,
            .token_has_been_found = false,
            .token = Token.doctype(allocator),
            .allocator = allocator
        };
    }

    pub fn deinit(self: *Tokenizer) void {

    }

    pub fn get_tokens(self: *Tokenizer, html: []u8) ![]Token {
        var tokens = TokenArray.init(self.allocator);
        for (html) | character | {
            try self.handle(character);
            if (self.token_has_been_found) {
                try tokens.append(self.token);
                self.token_has_been_found = false;
            }
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
                self.token = Token.closing_tag(self.allocator);
                self.state = State.ReadClosingTagName;
            },
            else => {
                self.token = Token.opening_tag(self.allocator);
                try self.token.content.push(character);
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
            else => try self.token.content.push(character)
        }
    }


    fn handle_read_attributes(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '>' => {
                self.state = State.ReadContent;
                self.token_has_been_found = true;
            },
            ' ' => return,
            else => {
                self.token = Token.attribute_key(self.allocator);
                try self.token.content.push(character);
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
                try self.token.content.push(character);
            }
        }
    }

    fn handle_read_attribute_value_opening_quote(self: *Tokenizer, character: u8) void {
        switch(character) {
            '"' =>{
                self.token = Token.attribute_value(self.allocator);
                self.state = State.ReadAttributeValue;
            },
            else => self.state = State.Done
        }
    }

    fn handle_read_attribute_value(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '"' => {
                self.token_has_been_found = true;
                self.state = State.ReadAttributes;
            },
            else => {
                try self.token.content.push(character);
            }
        }
    }

    fn handle_read_closing_tag_name(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '>' =>  {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            else => try self.token.content.push(character)
        }
    }

    fn handle_read_content(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '<' => self.state = State.ReadTagName,
            ' ' => return,
            '\n' => return,
            else => {
                self.token = Token.text(self.allocator);
                try self.token.content.push(character);
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
            else => try self.token.content.push(character),
        }
    }

    fn handle_read_opening_comment_or_doctype(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '-' => self.state = State.ReadOpeningCommentDash,
            'D' => {
                try self.token.content.push(character);
                self.state = State.ReadDoctype;
            },
            else => return
        }
    }

    fn handle_read_opening_comment_dash(self: *Tokenizer, character: u8) void {
        switch(character) {
            '-' => {
                self.token = Token.comment(self.allocator);
                self.state = State.ReadCommentContent;
            },
            else => self.state = State.Done,
        }
    }

    fn handle_read_comment_content(self: *Tokenizer, character: u8) !void {
        switch(character) {
            '-' => self.state = State.ReadClosingComment,
            else => try self.token.content.push(character)
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
            else => try self.token.content.push(character)
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
// -----------------

// ----- Test Get Tokens -----

test "Can tokenize div with text" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = try tokenizer.get_tokens(&"<div>Hello Hppy</div>");
    assert(tokens.len == 3);
    assert(tokens[0].kind == TokenKind.OpeningTag);
    assert(tokens[0].content.equals("div"));
    assert(tokens[1].kind == TokenKind.Text);
    assert(tokens[1].content.equals("Hello Hppy"));
    assert(tokens[2].kind == TokenKind.ClosingTag);
    assert(tokens[2].content.equals("div"));
}

test "Can tokenize doctype" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = try tokenizer.get_tokens(&"<!DOCTYPE html>");
    assert(tokens.len == 1);
    assert(tokens[0].kind == TokenKind.Doctype);
    assert(tokens[0].content.equals("DOCTYPE html"));
}

test "Can tokenize comment" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = try tokenizer.get_tokens(&"<!-- Hello Hppy -->");
    assert(tokens.len == 1);
    assert(tokens[0].kind == TokenKind.Comment);
    assert(tokens[0].content.equals(" Hello Hppy "));
}

// ----- Test SeekOpeningTag state -----

test "Handle - Given SeekOpeningTag state - When encounter < character - Then switch state to ReadTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    try tokenizer.handle('<');
    assert(tokenizer.state == State.ReadTagName);
}

test "Handle - Given SeekOpeningTag state - When encounter any other character - Then keep state to SeekOpeningTag." {
    var tokenizer = Tokenizer.init(&alloc);
    try tokenizer.handle('a');
    assert(tokenizer.state == State.SeekOpeningTag);
}

// ----- Test ReadClosingTagName state -----

test "Handle - Given ReadClosingTagName state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingTagName;
    try tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadClosingTagName state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingTagName;
    try tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadClosingTagName state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingTagName;
    try tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

// ----- Test ReadTagName state -----

test "Handle - Given ReadTagName state - When encounter ! character - Then switch state to ReadOpeningCommentOrDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    try tokenizer.handle('!');
    assert(tokenizer.state == State.ReadOpeningCommentOrDoctype);
}

test "Handle - Given ReadTagName state - When encounter / character - Then switch state to ReadClosingTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    try tokenizer.handle('/');
    assert(tokenizer.state == State.ReadClosingTagName);
}

test "Handle - Given ReadTagName state - When encounter / character - Then start to build a closing tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    try tokenizer.handle('/');
    assert(tokenizer.token.kind == TokenKind.ClosingTag);
}

test "Handle - Given ReadTagName state - When encounter any other character - Then switch state to ReadOpeningTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.ReadOpeningTagName);
}

test "Handle - Given ReadTagName state - When encounter any other character - Then start to build a opening tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    try tokenizer.handle('a');
    assert(tokenizer.token.kind == TokenKind.OpeningTag);
}

test "Handle - Given ReadTagName state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    try tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

// ----- Test ReadOpeningTagName state -----

test "Handle - Given ReadOpeningTagName state - When encounter a space character - Then switch state to ReadAttributes." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    try tokenizer.handle(' ');
    assert(tokenizer.state == State.ReadAttributes);
}

test "Handle - Given ReadOpeningTagName state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    try tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadOpeningTagName state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    try tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadOpeningTagName state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    try tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}


// ----- Test ReadAttributes state -----

test "Handle - Given ReadAttributes state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributes;
    try tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadAttributes state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributes;
    try tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadAttributes state - When encounter any other character - Then switch state to ReadAttributeKey." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributes;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.ReadAttributeKey);
}

test "Handle - Given ReadAttributes state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributes;
    try tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

test "Handle - Given ReadAttributes state - When encounter any other character - Then start to build an attribute tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributes;
    try tokenizer.handle('a');
    assert(tokenizer.token.kind == TokenKind.AttributeKey);
}


// ----- Test ReadAttributeKey state -----

test "Handle - Given ReadAttributeKey state - When encounter space character - Then switch state to ReadAttributes." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributeKey;
    try tokenizer.handle(' ');
    assert(tokenizer.state == State.ReadAttributes);
}

test "Handle - Given ReadAttributeKey state - When encounter space character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributeKey;
    try tokenizer.handle(' ');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadAttributeKey state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributeKey;
    try tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadAttributeKey state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributeKey;
    try tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadAttributeKey state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributeKey;
    try tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}


// ----- Test ReadContent state -----

test "Handle - Given ReadContent state - When encounter < character - Then switch state to ReadTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    try tokenizer.handle('<');
    assert(tokenizer.state == State.ReadTagName);
}

test "Handle - Given ReadContent state - When encounter a space character - Then keep state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    try tokenizer.handle(' ');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadContent state - When encounter a carriage return character - Then keep state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    try tokenizer.handle('\n');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadContent state - When encounter any other character - Then switch state to ReadText." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.ReadText);
}

test "Handle - Given ReadContent state - When encounter any other character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    try tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

test "Handle - Given ReadContent state - When encounter any other character - Then start to build a text tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    try tokenizer.handle('a');
    assert(tokenizer.token.kind == TokenKind.Text);
}

// ----- Test ReadText state -----

test "Handle - Given ReadText state - When encounter < character - Then switch state to ReadTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadText;
    try tokenizer.handle('<');
    assert(tokenizer.state == State.ReadTagName);
}

test "Handle - Given ReadText state - When encounter < character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadText;
    try tokenizer.handle('<');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadText state - When encounter any other character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadText;
    try tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

// ----- Test ReadOpeningCommentOrDoctype state -----

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter - character - Then switch state to ReadOpeningCommentDash." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    try tokenizer.handle('-');
    assert(tokenizer.state == State.ReadOpeningCommentDash);
}

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter D character - Then switch state to ReadDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    try tokenizer.handle('D');
    assert(tokenizer.state == State.ReadDoctype);
}

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter D character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    try tokenizer.handle('D');
    assert(tokenizer.token.content.equals("D"));
}

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter any other character - Then keep state to ReadOpeningCommentOrDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.ReadOpeningCommentOrDoctype);
}

// ----- Test ReadOpeningCommentDash state -----

test "Handle - Given ReadOpeningCommentDash state - When encounter - character - Then switch state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentDash;
    try tokenizer.handle('-');
    assert(tokenizer.state == State.ReadCommentContent);
}

test "Handle - Given ReadOpeningCommentDash state - When encounter - character - Then start to build a comment tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentDash;
    try tokenizer.handle('-');
    assert(tokenizer.token.kind == TokenKind.Comment);
}

test "Handle - Given ReadOpeningCommentDash state - When encounter any other character - Then switch state to Done." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentDash;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.Done);
}

// ----- Test ReadCommentContent state -----

test "Handle - Given ReadCommentContent state - When encounter - character - Then switch state to ReadClosingComment." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadCommentContent;
    try tokenizer.handle('-');
    assert(tokenizer.state == State.ReadClosingComment);
}

test "Handle - Given ReadCommentContent state - When encounter any other character - Then keep state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadCommentContent;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.ReadCommentContent);
}

// ----- Test ReadClosingComment state -----

test "Handle - Given ReadClosingComment state - When encounter - character - Then switch state to ReadClosingCommentDash." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingComment;
    try tokenizer.handle('-');
    assert(tokenizer.state == State.ReadClosingCommentDash);
}

test "Handle - Given ReadClosingComment state - When encounter any other character - Then keep state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingComment;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.ReadCommentContent);
}

// ----- Test ReadClosingCommentDash state -----

test "Handle - Given ReadClosingCommentDash state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingCommentDash;
    try tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadClosingCommentDash state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingCommentDash;
    try tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadClosingCommentDash state - When encounter any other character - Then keep state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingCommentDash;
    try tokenizer.handle('a');
    assert(tokenizer.state == State.ReadCommentContent);
}

// ----- Test ReadDoctype state -----

test "Handle - Given ReadDoctype state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    try tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadDoctype state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    try tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadDoctype state - When encounter any other character - Then keep state to ReadDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    try tokenizer.handle('O');
    assert(tokenizer.state == State.ReadDoctype);
}

test "Handle - Given ReadDoctype state - When encounter any other character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    try tokenizer.handle('O');
    assert(tokenizer.token.content.equals("O"));
}


// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
