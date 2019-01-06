use crate::parser::state::State;

pub struct Context {
    state: State,
    tag_name: String
}

impl Context {

    pub fn new() -> Self {
        Context::from_state(State::SeekOpeningTag)
    }

    pub fn from_state(state: State) -> Self {
        Context {state: state, tag_name: String::new()}
    }

    pub fn handle(&mut self, character: char) {
        match self.state {
            State::Done => println!("Done"),
            State::ReadAttributes => self.handle_read_attributes(character),
            State::ReadClosingComment => self.handle_read_closing_comment(character),
            State::ReadClosingCommentDash => self.handle_read_closing_comment_dash(character),
            State::ReadClosingTagName => self.handle_read_closing_tag_name(character),
            State::ReadCommentContent => self.handle_read_comment_content(character),
            State::ReadContent => self.handle_read_content(character),
            State::ReadDoctype => self.handle_read_doctype(character),
            State::ReadOpeningCommentDash => self.handle_read_opening_comment_dash(character),
            State::ReadOpeningCommentOrDoctype => {
                self.handle_read_opening_comment_or_doctype(character)
            }
            State::ReadOpeningTagName => self.handle_read_opening_tag_name(character),
            State::ReadTagName => self.handle_read_tag_name(character),
            State::ReadText => self.handle_read_text(character),
            State::SeekOpeningTag => self.handle_opening_tag(character),
        }
    }

    fn handle_opening_tag(&mut self, character: char) {
        if character == '<' {
            self.state = State::ReadTagName;
        }
    }

    fn handle_read_tag_name(&mut self, character: char) {
        if character == '!' {
            self.state = State::ReadOpeningCommentOrDoctype;
        } else {
            if character == '/' {
                self.state = State::ReadClosingTagName;
            } else {
                self.state = State::ReadOpeningTagName;
            }
            self.tag_name.push(character);
        }
    }

    fn handle_read_opening_tag_name(&mut self, character: char) {
        if character == '>' {
            // Create a node here.
            self.state = State::ReadContent;
        } else if character == ' ' {
            self.state = State::ReadAttributes;
        } else {
            // Add the character to the tag buffer.
        }
    }

    fn handle_read_attributes(&mut self, character: char) {
        if character == '>' {
            // Create a node from the tag buffer a, set its attribute from
            // the attribute buffer.
            self.state = State::ReadContent;
        } else {
            // Amend the character to the attribute buffer.
        }
    }

    fn handle_read_closing_tag_name(&mut self, character: char) {
        if character == '>' {
            // Create a node from the tag buffer.
            self.state = State::ReadContent;
        } else {
            // Amend the character to the tag buffer.
        }
    }

    fn handle_read_content(&mut self, character: char) {
        if character == '<' {
            self.state = State::ReadTagName;
        } else {
            // Amend token to the content buffer
            self.state = State::ReadText
        }
    }

    fn handle_read_text(&mut self, character: char) {
        if character == '<' {
            // Create a text node from the text buffer.
            self.state = State::ReadTagName;
        } else {
            // Amend character to the text buffer.
        }
    }

    fn handle_read_opening_comment_or_doctype(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadOpeningCommentDash;
        } else if character == 'D' {
            self.state = State::ReadDoctype;
        }
    }

    fn handle_read_opening_comment_dash(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadCommentContent;
        } else {
            self.state = State::Done;
        }
    }

    fn handle_read_comment_content(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadClosingComment;
        }
    }

    fn handle_read_closing_comment(&mut self, character: char) {
        if character == '-' {
            self.state = State::ReadClosingCommentDash;
        } else {
            self.state = State::ReadCommentContent;
        }
    }

    fn handle_read_closing_comment_dash(&mut self, character: char) {
        if character == '>' {
            self.state = State::ReadContent;
        } else {
            self.state = State::ReadCommentContent;
        }
    }

    fn handle_read_doctype(&mut self, character: char) {
        if character == '>' {
            self.state = State::ReadContent;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{Context, State};

    mod handle_opening_tag {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_an_opening_chevron() {
            let mut context = Context::from_state(State::SeekOpeningTag);
            context.handle_opening_tag('<');
            assert_eq!(context.state, State::ReadTagName);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::SeekOpeningTag);
            context.handle_opening_tag('a');
            assert_eq!(context.state, State::SeekOpeningTag);
        }
    }

    mod handle_read_tag_name {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_an_exclamation_mark() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('!');
            assert_eq!(context.state, State::ReadOpeningCommentOrDoctype);
        }

        #[test]
        fn test_tag_name_is_not_amended_when_process_an_exclamation_mark() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('!');
            assert_eq!(context.tag_name, "");
        }

        #[test]
        fn test_next_state_when_process_a_slash() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('/');
            assert_eq!(context.state, State::ReadClosingTagName);
        }

        #[test]
        fn test_tag_name_is_amended_when_process_a_slash() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('/');
            assert_eq!(context.tag_name, "/");
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('a');
            assert_eq!(context.state, State::ReadOpeningTagName);
        }

        #[test]
        fn test_tag_name_is_amended_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('a');
            assert_eq!(context.tag_name, "a");
        }
    }

    mod handle_read_opening_tag_name {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_closing_chevron() {
            let mut context = Context::from_state(State::ReadOpeningTagName);
            context.handle_read_opening_tag_name('>');
            assert_eq!(context.state, State::ReadContent);
        }

        #[test]
        fn test_next_state_when_process_a_whitespace() {
            let mut context = Context::from_state(State::ReadOpeningTagName);
            context.handle_read_opening_tag_name(' ');
            assert_eq!(context.state, State::ReadAttributes);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadOpeningTagName);
            context.handle_read_opening_tag_name('a');
            assert_eq!(context.state, State::ReadOpeningTagName);
        }
    }

    mod handle_read_attributes {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_closing_chevron() {
            let mut context = Context::from_state(State::ReadAttributes);
            context.handle_read_attributes('>');
            assert_eq!(context.state, State::ReadContent);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadAttributes);
            context.handle_read_attributes('a');
            assert_eq!(context.state, State::ReadAttributes);
        }
    }

    mod handle_read_closing_tag_name {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_closing_chevron() {
            let mut context = Context::from_state(State::ReadClosingTagName);
            context.handle_read_closing_tag_name('>');
            assert_eq!(context.state, State::ReadContent);
        }
    
        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadClosingTagName);
            context.handle_read_closing_tag_name('a');
            assert_eq!(context.state, State::ReadClosingTagName);
        }
    }


    mod handle_read_content {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_an_opening_chevron() {
            let mut context = Context::from_state(State::ReadContent);
            context.handle_read_content('<');
            assert_eq!(context.state, State::ReadTagName);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadContent);
            context.handle_read_content('a');
            assert_eq!(context.state, State::ReadText);
        }
    }
    

    mod handle_read_text {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_an_opening_chevron() {
            let mut context = Context::from_state(State::ReadText);
            context.handle_read_text('<');
            assert_eq!(context.state, State::ReadTagName);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadText);
            context.handle_read_text('a');
            assert_eq!(context.state, State::ReadText);
        }
    }


    mod handle_read_opening_comment_or_doctype {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_dash() {
            let mut context = Context::from_state(State::ReadOpeningCommentOrDoctype);
            context.handle_read_opening_comment_or_doctype('-');
            assert_eq!(context.state, State::ReadOpeningCommentDash);
        }

        #[test]
        fn test_next_state_when_process_a_d() {
            let mut context = Context::from_state(State::ReadOpeningCommentOrDoctype);
            context.handle_read_opening_comment_or_doctype('D');
            assert_eq!(context.state, State::ReadDoctype);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadOpeningCommentOrDoctype);
            context.handle_read_opening_comment_or_doctype('a');
            assert_eq!(context.state, State::ReadOpeningCommentOrDoctype);
        }
    }


    mod handle_read_opening_comment_dash {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_dash() {
            let mut context = Context::from_state(State::ReadOpeningCommentDash);
            context.handle_read_opening_comment_dash('-');
            assert_eq!(context.state, State::ReadCommentContent);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadOpeningCommentDash);
            context.handle_read_opening_comment_dash('a');
            assert_eq!(context.state, State::Done);
        }
    }

    mod handle_read_comment_content {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_dash() {
            let mut context = Context::from_state(State::ReadCommentContent);
            context.handle_read_comment_content('-');
            assert_eq!(context.state, State::ReadClosingComment);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadCommentContent);
            context.handle_read_comment_content('a');
            assert_eq!(context.state, State::ReadCommentContent);
        }
    }


    mod handle_read_closing_comment {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_dash() {
            let mut context = Context::from_state(State::ReadClosingComment);
            context.handle_read_closing_comment('-');
            assert_eq!(context.state, State::ReadClosingCommentDash);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadClosingComment);
            context.handle_read_closing_comment('a');
            assert_eq!(context.state, State::ReadCommentContent);
        }
    }

    mod handle_read_closing_comment_dash {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_closing_chevron() {
            let mut context = Context::from_state(State::ReadClosingCommentDash);
            context.handle_read_closing_comment_dash('>');
            assert_eq!(context.state, State::ReadContent);
        }

        #[test]
        fn test_next_state_when_process_with_any_other_character() {
            let mut context = Context::from_state(State::ReadClosingCommentDash);
            context.handle_read_closing_comment_dash('a');
            assert_eq!(context.state, State::ReadCommentContent);
        }
    }

    mod handle_read_doctype {
        use super::{Context, State};

        #[test]
        fn test_next_state_when_process_a_closing_chevron() {
            let mut context = Context::from_state(State::ReadDoctype);
            context.handle_read_doctype('>');
            assert_eq!(context.state, State::ReadContent);
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadDoctype);
            context.handle_read_doctype('a');
            assert_eq!(context.state, State::ReadDoctype);
        }
    }
}
