use crate::parser::state::State;


pub struct Context {
    state: State,
    token_has_been_found: bool,
    token_name: String,
    token_text_content: String,
}

impl Context {
    pub fn new() -> Self {
        Context::from_state(State::SeekOpeningTag)
    }

    pub fn from_state(state: State) -> Self {
        Context {
            state: state,
            token_has_been_found: false,
            token_name: String::new(),
            token_text_content: String::new(),
        }
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

    pub fn token_has_been_found(&self) -> bool {
        self.token_has_been_found
    }

    pub fn get_token_name(&self) -> &str {
        &self.token_name
    }

    pub fn get_token_text_content(&self) -> &str {
        &self.token_text_content
    }

    pub fn clear_token(&mut self) {
        self.token_name.clear();
        self.token_text_content.clear();
        self.token_has_been_found = false;
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
            self.token_name.push(character);
        }
    }

    fn handle_read_opening_tag_name(&mut self, character: char) {
        if character == '>' {
            self.token_has_been_found = true;
            self.state = State::ReadContent;
        } else if character == ' ' {
            self.state = State::ReadAttributes;
        } else {
            self.token_name.push(character);
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
            self.token_name.push(character);
        }
    }

    fn handle_read_content(&mut self, character: char) {
        if character == '<' {
            self.state = State::ReadTagName;
        } else {
            self.token_text_content.push(character);
            self.state = State::ReadText
        }
    }

    fn handle_read_text(&mut self, character: char) {
        if character == '<' {
            self.token_has_been_found = true;
            self.state = State::ReadTagName;
        } else {
            self.token_text_content.push(character);
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

    mod clear_token {
        use super::Context;

        #[test]
        fn test_clear_every_token_related_buffer() {
            let mut context = Context::new();
            context.token_name.push_str("div");
            context.token_text_content.push_str("Hello Hppy!");
            context.clear_token();

            assert_eq!(context.token_name.len(), 0);
            assert_eq!(context.token_text_content.len(), 0);
        }

        #[test]
        fn test_clear_token_notification() {
            let mut context = Context::new();
            context.token_has_been_found = true;
            context.clear_token();

            assert!(context.token_has_been_found == false);
        }
    }

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
        fn test_token_name_is_not_amended_when_process_an_exclamation_mark() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('!');
            assert_eq!(context.token_name, "");
        }

        #[test]
        fn test_next_state_when_process_a_slash() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('/');
            assert_eq!(context.state, State::ReadClosingTagName);
        }

        #[test]
        fn test_token_name_is_amended_when_process_a_slash() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('/');
            assert_eq!(context.token_name, "/");
        }

        #[test]
        fn test_next_state_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('a');
            assert_eq!(context.state, State::ReadOpeningTagName);
        }

        #[test]
        fn test_token_name_is_amended_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadTagName);
            context.handle_read_tag_name('a');
            assert_eq!(context.token_name, "a");
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
        fn test_notify_that_a_token_has_been_found_when_process_a_closing_chevron() {
            let mut context = Context::from_state(State::ReadOpeningTagName);
            context.handle_read_opening_tag_name('>');
            assert!(context.token_has_been_found);
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

        #[test]
        fn test_token_name_is_amended_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadOpeningTagName);
            context.handle_read_opening_tag_name('a');
            assert_eq!(context.token_name, "a");
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

        #[test]
        fn test_token_name_is_amended_when_process_any_other_character() {
            let mut context = Context::from_state(State::ReadClosingTagName);
            context.handle_read_closing_tag_name('a');
            assert_eq!(context.token_name, "a");
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
        fn test_notify_a_token_has_been_found_when_process_an_opening_chevron() {
            let mut context = Context::from_state(State::ReadText);
            context.handle_read_text('<');
            assert!(context.token_has_been_found);
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
