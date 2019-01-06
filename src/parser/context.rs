use crate::parser::state::State;

pub struct Context {
    pub state: State,
}

impl Context {
    pub fn handle_opening_tag(&mut self, character: char) {
        if character == '<' {
            self.state = State::ReadTagName;
        }
    }

    pub fn handle_read_tag_name(&mut self, character: char) {
        if character == '!' {
            self.state = State::ReadOpeningCommentOrDoctype;
        } else if character == '/' {
            self.state = State::ReadClosingTagName;
        } else {
            self.state = State::ReadOpeningTagName;
        }
    }

    pub fn handle_read_opening_tag_name(&mut self, character: char) {
        if character == '>' {
            // Create a node here.
            self.state = State::ReadContent;
        } else if character == ' ' {
            self.state = State::ReadAttributes;
        } else {
            // Add the character to the tag buffer.
        }
    }

    pub fn handle_read_attributes(&mut self, character: char) {
        if character == '>' {
            // Create a node from the tag buffer a, set its attribute from
            // the attribute buffer.
            self.state = State::ReadContent;
        } else {
            // Amend the character to the attribute buffer.
        }
    }

    pub fn handle_read_closing_tag_name(&mut self, character: char) {
        if character == '>' {
            // Create a node from the tag buffer.
            self.state = State::ReadContent;
        } else {
            // Amend the character to the tag buffer.
        }
    }

    pub fn handle_read_content(&mut self, character: char) {
        if character == '<' {
            self.state = State::ReadTagName;
        } else {
            // Amend token to the content buffer
            self.state = State::ReadText
        }
    }

    pub fn handle_read_text(&mut self, character: char) {
        if character == '<' {
            // Create a text node from the text buffer.
            self.state = State::ReadTagName;
        } else {
            // Amend character to the text buffer.
        }
    }

    pub fn handle_read_opening_comment_or_doctype(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadOpeningCommentDash;
        } else if character == 'D' {
            self.state = State::ReadDoctype;
        }
    }

    pub fn handle_read_opening_comment_dash(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadCommentContent;
        } else {
            self.state = State::Done;
        }
    }
    
    pub fn handle_read_comment_content(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadClosingComment;
        }
    }

    pub fn handle_read_closing_comment(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadClosingCommentDash;
        } else {
            self.state = State::ReadCommentContent;
        }
    }

    pub fn handle_read_closing_comment_dash(&mut self, character: char) {
        if character == '>' {
            self.state = State::ReadContent;
        } else {
            self.state = State::ReadCommentContent;
        }
    }

    pub fn handle_read_doctype(&mut self, character: char) {
        if character == '>' {
            self.state = State::ReadContent;
        }
    }

}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_handle_opening_tag_with_opening_chevron() {
        let mut context = Context {
            state: State::SeekOpeningTag,
        };
        context.handle_opening_tag('<');
        assert_eq!(context.state, State::ReadTagName);
    }

    #[test]
    fn test_handle_opening_tag_with_any_other_character() {
        let mut context = Context {
            state: State::SeekOpeningTag,
        };
        context.handle_opening_tag('a');
        assert_eq!(context.state, State::SeekOpeningTag);
    }

    #[test]
    fn test_handle_read_tag_name_with_exclamation_mark() {
        let mut context = Context {
            state: State::ReadTagName,
        };
        context.handle_read_tag_name('!');
        assert_eq!(context.state, State::ReadOpeningCommentOrDoctype);
    }

    #[test]
    fn test_handle_read_tag_name_with_slash() {
        let mut context = Context {
            state: State::ReadTagName,
        };
        context.handle_read_tag_name('/');
        assert_eq!(context.state, State::ReadClosingTagName);
    }

    #[test]
    fn test_handle_read_tag_name_with_any_other_character() {
        let mut context = Context {
            state: State::ReadTagName,
        };
        context.handle_read_tag_name('a');
        assert_eq!(context.state, State::ReadOpeningTagName);
    }

    #[test]
    fn test_handle_read_opening_tag_name_with_a_closing_chevron() {
        let mut context = Context {
            state: State::ReadOpeningTagName,
        };
        context.handle_read_opening_tag_name('>');
        assert_eq!(context.state, State::ReadContent);
    }

    #[test]
    fn test_handle_read_opening_tag_name_with_a_whitespace() {
        let mut context = Context {
            state: State::ReadOpeningTagName,
        };
        context.handle_read_opening_tag_name(' ');
        assert_eq!(context.state, State::ReadAttributes);
    }

    #[test]
    fn test_handle_read_opening_tag_name_with_any_other_character() {
        let mut context = Context {
            state: State::ReadOpeningTagName,
        };
        context.handle_read_opening_tag_name('a');
        assert_eq!(context.state, State::ReadOpeningTagName);
    }

    #[test]
    fn test_handle_read_attributes_with_a_closing_chevron() {
        let mut context = Context {
            state: State::ReadAttributes,
        };
        context.handle_read_attributes('>');
        assert_eq!(context.state, State::ReadContent);
    }

    #[test]
    fn test_handle_read_attributes_with_any_other_character() {
        let mut context = Context {
            state: State::ReadAttributes,
        };
        context.handle_read_attributes('a');
        assert_eq!(context.state, State::ReadAttributes);
    }

    #[test]
    fn test_handle_read_closing_tag_name_with_any_other_character() {
        let mut context = Context {
            state: State::ReadClosingTagName,
        };
        context.handle_read_closing_tag_name('a');
        assert_eq!(context.state, State::ReadClosingTagName);
    }

    #[test]
    fn test_handle_read_closing_tag_name_with_closing_chevron() {
        let mut context = Context {
            state: State::ReadClosingTagName,
        };
        context.handle_read_closing_tag_name('>');
        assert_eq!(context.state, State::ReadContent);
    }

    #[test]
    fn test_handle_read_content_with_an_opening_chevron() {
        let mut context = Context {
            state: State::ReadContent,
        };
        context.handle_read_content('<');
        assert_eq!(context.state, State::ReadTagName);
    }

    #[test]
    fn test_handle_read_content_with_any_other_character() {
        let mut context = Context {
            state: State::ReadContent,
        };
        context.handle_read_content('a');
        assert_eq!(context.state, State::ReadText);
    }


    #[test]
    fn test_handle_read_text_with_an_opening_chevron() {
        let mut context = Context {
            state: State::ReadText,
        };
        context.handle_read_text('<');
        assert_eq!(context.state, State::ReadTagName);
    }

    #[test]
    fn test_handle_read_text_with_any_other_character() {
        let mut context = Context {
            state: State::ReadText,
        };
        context.handle_read_text('a');
        assert_eq!(context.state, State::ReadText);
    }

    #[test]
    fn test_handle_read_opening_comment_or_doctype_with_a_dash() {
        let mut context = Context {
            state: State::ReadOpeningCommentOrDoctype,
        };
        context.handle_read_opening_comment_or_doctype('-');
        assert_eq!(context.state, State::ReadOpeningCommentDash);
    }

    #[test]
    fn test_handle_read_opening_comment_or_doctype_with_a_d() {
        let mut context = Context {
            state: State::ReadOpeningCommentOrDoctype,
        };
        context.handle_read_opening_comment_or_doctype('D');
        assert_eq!(context.state, State::ReadDoctype);
    }

    #[test]
    fn test_handle_read_opening_comment_or_doctype_with_any_other_character() {
        let mut context = Context {
            state: State::ReadOpeningCommentOrDoctype,
        };
        context.handle_read_opening_comment_or_doctype('a');
        assert_eq!(context.state, State::ReadOpeningCommentOrDoctype);
    }

    #[test]
    fn test_handle_read_opening_comment_dash_with_a_dash() {
        let mut context = Context {
            state: State::ReadOpeningCommentDash,
        };
        context.handle_read_opening_comment_dash('-');
        assert_eq!(context.state, State::ReadCommentContent);
    }

    #[test]
    fn test_handle_read_opening_comment_dash_with_any_other_character() {
        let mut context = Context {
            state: State::ReadOpeningCommentDash,
        };
        context.handle_read_opening_comment_dash('a');
        assert_eq!(context.state, State::Done);
    }

    #[test]
    fn test_handle_read_comment_content_with_a_dash() {
        let mut context = Context {
            state: State::ReadCommentContent,
        };
        context.handle_read_comment_content('-');
        assert_eq!(context.state, State::ReadClosingComment);
    }

    #[test]
    fn test_handle_read_comment_content_with_any_other_character() {
        let mut context = Context {
            state: State::ReadCommentContent,
        };
        context.handle_read_comment_content('a');
        assert_eq!(context.state, State::ReadCommentContent);
    }

    #[test]
    fn test_handle_read_closing_comment_with_a_dash() {
        let mut context = Context {
            state: State::ReadClosingComment,
        };
        context.handle_read_closing_comment('-');
        assert_eq!(context.state, State::ReadClosingCommentDash);
    }

    #[test]
    fn test_handle_read_closing_comment_with_any_other_character() {
        let mut context = Context {
            state: State::ReadClosingComment,
        };
        context.handle_read_closing_comment('a');
        assert_eq!(context.state, State::ReadCommentContent);
    }


    #[test]
    fn test_handle_read_closing_comment_dash_with_a_closing_chevron() {
        let mut context = Context {
            state: State::ReadClosingCommentDash,
        };
        context.handle_read_closing_comment_dash('>');
        assert_eq!(context.state, State::ReadContent);
    }

    #[test]
    fn test_handle_read_closing_comment_dash_with_any_other_character() {
        let mut context = Context {
            state: State::ReadClosingCommentDash,
        };
        context.handle_read_closing_comment_dash('a');
        assert_eq!(context.state, State::ReadCommentContent);
    }

    #[test]
    fn test_handle_read_doctype_with_a_closing_chevron() {
        let mut context = Context {
            state: State::ReadDoctype,
        };
        context.handle_read_doctype('>');
        assert_eq!(context.state, State::ReadContent);
    }

    #[test]
    fn test_handle_read_doctype_with_any_other_character() {
        let mut context = Context {
            state: State::ReadDoctype,
        };
        context.handle_read_doctype('a');
        assert_eq!(context.state, State::ReadDoctype);
    }
}
