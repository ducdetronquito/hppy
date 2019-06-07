const std = @import("std");
const warn = std.debug.warn;
const tag = @import("tag.zig");
const state = @import("state.zig");
const tokenizer = @import("token.zig");

pub fn main() void {
    warn("FromName?: {}\n", tag.Tag.FromName("div"));
    warn("State: {}\n", state.State.Done);

    const toto = tokenizer.Token {
        .kind = token.TokenKind.OpeningTag,
        .content = "Toto"
    };
    warn("Token: {}\n", toto);
    warn("is_text: {}\n", toto.IsClosingTag());
}
