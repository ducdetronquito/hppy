const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const State = @import("state.zig").State;
const Token = @import("token.zig").Token;
const String = @import("string.zig").String;
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

    pub fn get_tokens(self: *Tokenizer, html: []u8) TokenArray {
        var tokens = TokenArray.init(self.allocator);
        for (html) | character | {
            self.handle(character);
            if (self.token_has_been_found) {
                tokens.append(self.token) catch unreachable;
                self.token_has_been_found = false;
            }
        }
        return tokens;
    }

    fn handle(self: *Tokenizer, character: u8) void {
        switch(self.state) {
            State.SeekOpeningTag => self.handle_seek_opening_tag(character),
            State.ReadClosingTagName => self.handle_read_closing_tag_name(character),
            State.ReadTagName => self.handle_read_tag_name(character),
            State.ReadOpeningTagName => self.handle_read_opening_tag_name(character),
            State.ReadAttributes => self.handle_read_attributes(character),
            State.ReadContent => self.handle_read_content(character),
            State.ReadText => self.handle_read_text(character),
            State.ReadOpeningCommentOrDoctype => self.handle_read_opening_comment_or_doctype(character),
            State.ReadOpeningCommentDash => self.handle_read_opening_comment_dash(character),
            State.ReadCommentContent => self.handle_read_comment_content(character),
            State.ReadClosingComment => self.handle_read_closing_comment(character),
            State.ReadClosingCommentDash => self.handle_read_closing_comment_dash(character),
            State.ReadDoctype => self.handle_read_doctype(character),
            else => return,
        }
    }

    fn handle_seek_opening_tag(self: *Tokenizer, character: u8) void {
        switch(character) {
            '<' => self.state = State.ReadTagName,
            else => return
        }
    }

    fn handle_read_tag_name(self: *Tokenizer, character: u8) void {
        switch(character) {
            '!' => self.state = State.ReadOpeningCommentOrDoctype,
            '/' => {
                self.token = Token.closing_tag(self.allocator);
                self.state = State.ReadClosingTagName;
            },
            else => {
                self.token = Token.opening_tag(self.allocator);
                self.token.content.push(character);
                self.state = State.ReadOpeningTagName;
            }
        }
    }

    fn handle_read_opening_tag_name(self: *Tokenizer, character: u8) void {
        switch(character) {
            '>' => {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            ' ' => self.state = State.ReadAttributes,
            else => self.token.content.push(character)
        }
    }

    fn handle_read_attributes(self: *Tokenizer, character: u8) void {
        if (character == '>') {
            self.state = State.ReadContent;
        }
    }

    fn handle_read_closing_tag_name(self: *Tokenizer, character: u8) void {
        switch(character) {
            '>' =>  {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            else => self.token.content.push(character)
        }
    }

    fn handle_read_content(self: *Tokenizer, character: u8) void {
        switch(character) {
            '<' => self.state = State.ReadTagName,
            ' ' => return,
            '\n' => return,
            else => {
                self.token = Token.text(self.allocator);
                self.token.content.push(character);
                self.state = State.ReadText;
            }
        } 
    }

    fn handle_read_text(self: *Tokenizer, character: u8) void {
        switch(character) {
            '<' => {
                self.token_has_been_found = true;
                self.state = State.ReadTagName;
            },
            else => self.token.content.push(character),
        }
    }

    fn handle_read_opening_comment_or_doctype(self: *Tokenizer, character: u8) void {
        switch(character) {
            '-' => self.state = State.ReadOpeningCommentDash,
            'D' => {
                self.token.content.push(character);
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

    fn handle_read_comment_content(self: *Tokenizer, character: u8) void {
        switch(character) {
            '-' => self.state = State.ReadClosingComment,
            else => self.token.content.push(character)
        }
    }

    fn handle_read_closing_comment(self: *Tokenizer, character: u8) void {
        switch(character) {
            '-' => self.state = State.ReadClosingCommentDash,
            else => self.state = State.ReadCommentContent
        }
    }

    fn handle_read_doctype(self: *Tokenizer, character: u8) void {
        switch(character) {
            '>' => {
                self.token_has_been_found = true;
                self.state = State.ReadContent;
            },
            else => self.token.content.push(character)
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
    var tokens = tokenizer.get_tokens(&"<div>Hello Hppy</div>").toSlice();
    assert(tokens.len == 3);
    assert(tokens[0].is_opening_tag());
    assert(tokens[0].content.equals("div"));
    assert(tokens[1].is_text());
    assert(tokens[1].content.equals("Hello Hppy"));
    assert(tokens[2].is_closing_tag());
    assert(tokens[2].content.equals("div"));
}

test "Can tokenize doctype" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = tokenizer.get_tokens(&"<!DOCTYPE html>").toSlice();
    assert(tokens.len == 1);
    assert(tokens[0].is_doctype());
    assert(tokens[0].content.equals("DOCTYPE html"));
}

test "Can tokenize comment" {
    var tokenizer = Tokenizer.init(&alloc);
    var tokens = tokenizer.get_tokens(&"<!-- Hello Hppy -->").toSlice();
    assert(tokens.len == 1);
    assert(tokens[0].is_comment());
    assert(tokens[0].content.equals(" Hello Hppy "));
}

// ----- Test SeekOpeningTag state -----

test "Handle - Given SeekOpeningTag state - When encounter < character - Then switch state to ReadTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.handle('<');
    assert(tokenizer.state == State.ReadTagName);
}

test "Handle - Given SeekOpeningTag state - When encounter any other character - Then keep state to SeekOpeningTag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.handle('a');
    assert(tokenizer.state == State.SeekOpeningTag);
}

// ----- Test ReadClosingTagName state -----

test "Handle - Given ReadClosingTagName state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingTagName;
    tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadClosingTagName state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingTagName;
    tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadClosingTagName state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingTagName;
    tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

// ----- Test ReadTagName state -----

test "Handle - Given ReadTagName state - When encounter ! character - Then switch state to ReadOpeningCommentOrDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    tokenizer.handle('!');
    assert(tokenizer.state == State.ReadOpeningCommentOrDoctype);
}

test "Handle - Given ReadTagName state - When encounter / character - Then switch state to ReadClosingTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    tokenizer.handle('/');
    assert(tokenizer.state == State.ReadClosingTagName);
}

test "Handle - Given ReadTagName state - When encounter / character - Then start to build a closing tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    tokenizer.handle('/');
    assert(tokenizer.token.is_closing_tag());
}

test "Handle - Given ReadTagName state - When encounter any other character - Then switch state to ReadOpeningTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    tokenizer.handle('a');
    assert(tokenizer.state == State.ReadOpeningTagName);
}

test "Handle - Given ReadTagName state - When encounter any other character - Then start to build a opening tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    tokenizer.handle('a');
    assert(tokenizer.token.is_opening_tag());
}

test "Handle - Given ReadTagName state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadTagName;
    tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

// ----- Test ReadOpeningTagName state -----

test "Handle - Given ReadOpeningTagName state - When encounter a space character - Then switch state to ReadAttributes." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    tokenizer.handle(' ');
    assert(tokenizer.state == State.ReadAttributes);
}

test "Handle - Given ReadOpeningTagName state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadOpeningTagName state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadOpeningTagName state - When encounter any other character - Store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningTagName;
    tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

// ----- Test ReadAttributes state -----

test "Handle - Given ReadAttributes state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadAttributes;
    tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

// ----- Test ReadContent state -----

test "Handle - Given ReadContent state - When encounter < character - Then switch state to ReadTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    tokenizer.handle('<');
    assert(tokenizer.state == State.ReadTagName);
}

test "Handle - Given ReadContent state - When encounter a space character - Then keep state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    tokenizer.handle(' ');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadContent state - When encounter a carriage return character - Then keep state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    tokenizer.handle('\n');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadContent state - When encounter any other character - Then switch state to ReadText." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    tokenizer.handle('a');
    assert(tokenizer.state == State.ReadText);
}

test "Handle - Given ReadContent state - When encounter any other character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

test "Handle - Given ReadContent state - When encounter any other character - Then start to build a text tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadContent;
    tokenizer.handle('a');
    assert(tokenizer.token.is_text());
}

// ----- Test ReadText state -----

test "Handle - Given ReadText state - When encounter < character - Then switch state to ReadTagName." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadText;
    tokenizer.handle('<');
    assert(tokenizer.state == State.ReadTagName);
}

test "Handle - Given ReadText state - When encounter < character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadText;
    tokenizer.handle('<');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadText state - When encounter any other character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadText;
    tokenizer.handle('a');
    assert(tokenizer.token.content.equals("a"));
}

// ----- Test ReadOpeningCommentOrDoctype state -----

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter - character - Then switch state to ReadOpeningCommentDash." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    tokenizer.handle('-');
    assert(tokenizer.state == State.ReadOpeningCommentDash);
}

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter D character - Then switch state to ReadDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    tokenizer.handle('D');
    assert(tokenizer.state == State.ReadDoctype);
}

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter D character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    tokenizer.handle('D');
    assert(tokenizer.token.content.equals("D"));
}

test "Handle - Given ReadOpeningCommentOrDoctype state - When encounter any other character - Then keep state to ReadOpeningCommentOrDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentOrDoctype;
    tokenizer.handle('a');
    assert(tokenizer.state == State.ReadOpeningCommentOrDoctype);
}

// ----- Test ReadOpeningCommentDash state -----

test "Handle - Given ReadOpeningCommentDash state - When encounter - character - Then switch state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentDash;
    tokenizer.handle('-');
    assert(tokenizer.state == State.ReadCommentContent);
}

test "Handle - Given ReadOpeningCommentDash state - When encounter - character - Then start to build a comment tag." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentDash;
    tokenizer.handle('-');
    assert(tokenizer.token.is_comment());
}

test "Handle - Given ReadOpeningCommentDash state - When encounter any other character - Then switch state to Done." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadOpeningCommentDash;
    tokenizer.handle('a');
    assert(tokenizer.state == State.Done);
}

// ----- Test ReadCommentContent state -----

test "Handle - Given ReadCommentContent state - When encounter - character - Then switch state to ReadClosingComment." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadCommentContent;
    tokenizer.handle('-');
    assert(tokenizer.state == State.ReadClosingComment);
}

test "Handle - Given ReadCommentContent state - When encounter any other character - Then keep state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadCommentContent;
    tokenizer.handle('a');
    assert(tokenizer.state == State.ReadCommentContent);
}

// ----- Test ReadClosingComment state -----

test "Handle - Given ReadClosingComment state - When encounter - character - Then switch state to ReadClosingCommentDash." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingComment;
    tokenizer.handle('-');
    assert(tokenizer.state == State.ReadClosingCommentDash);
}

test "Handle - Given ReadClosingComment state - When encounter any other character - Then keep state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingComment;
    tokenizer.handle('a');
    assert(tokenizer.state == State.ReadCommentContent);
}

// ----- Test ReadClosingCommentDash state -----

test "Handle - Given ReadClosingCommentDash state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingCommentDash;
    tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadClosingCommentDash state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingCommentDash;
    tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadClosingCommentDash state - When encounter any other character - Then keep state to ReadCommentContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadClosingCommentDash;
    tokenizer.handle('a');
    assert(tokenizer.state == State.ReadCommentContent);
}

// ----- Test ReadDoctype state -----

test "Handle - Given ReadDoctype state - When encounter > character - Then switch state to ReadContent." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    tokenizer.handle('>');
    assert(tokenizer.state == State.ReadContent);
}

test "Handle - Given ReadDoctype state - When encounter > character - Then notify a token has been found." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    tokenizer.handle('>');
    assert(tokenizer.token_has_been_found == true);
}

test "Handle - Given ReadDoctype state - When encounter any other character - Then keep state to ReadDoctype." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    tokenizer.handle('O');
    assert(tokenizer.state == State.ReadDoctype);
}

test "Handle - Given ReadDoctype state - When encounter any other character - Then store the character." {
    var tokenizer = Tokenizer.init(&alloc);
    tokenizer.state = State.ReadDoctype;
    tokenizer.handle('O');
    assert(tokenizer.token.content.equals("O"));
}


// ----- Teardown -----
const teardown = direct_allocator.deinit();
// --------------------
