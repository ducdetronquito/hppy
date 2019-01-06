use crate::document::Document;
use crate::parser::context::Context;
use crate::parser::state::State;



fn parse(content: &str) -> Document {
    let mut context = Context {
        state: State::SeekOpeningTag,
    };
    let document = Document {};

    for c in content.chars() {
        match context.state {
            State::Done => println!("Done"),
            State::ReadAttributes => context.handle_read_attributes(c),
            State::ReadClosingComment => context.handle_read_closing_comment(c),
            State::ReadClosingCommentDash => context.handle_read_closing_comment_dash(c),
            State::ReadClosingTagName => context.handle_read_closing_tag_name(c),
            State::ReadCommentContent => context.handle_read_comment_content(c),
            State::ReadContent => context.handle_read_content(c),
            State::ReadDoctype => context.handle_read_doctype(c),
            State::ReadOpeningCommentDash => context.handle_read_opening_comment_dash(c),
            State::ReadOpeningCommentOrDoctype => context.handle_read_opening_comment_or_doctype(c),
            State::ReadOpeningTagName => context.handle_read_opening_tag_name(c),
            State::ReadTagName => context.handle_read_tag_name(c),
            State::ReadText => context.handle_read_text(c),
            State::SeekOpeningTag => context.handle_opening_tag(c),
        }
    }

    return document;
}

#[cfg(test)]
mod tests {

    #[test]
    fn test_parse() {
        assert_eq!(2+2, 4);
    }

}
