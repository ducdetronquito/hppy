use crate::document::Document;
use crate::tag::{Tag};
use crate::parser::tokenizer::Tokenizer;

pub fn parse(content: &str) -> Document {
    let mut document = Document::new();
    let mut scopes = Vec::new();

    for token in Tokenizer::get_tokens(content) {

        if token.is_closing_tag() {
            scopes.pop();
        }
        else {
            let parent_index: i32 = match scopes.last() {
                Some(x) => *x - 1,
                None => -1
            };
            if token.is_text() {
                document.push_text(&token.content, parent_index);
            }
            else if token.is_opening_tag() {
                document.push_tag(&token.content, parent_index);
                scopes.push(document.get_last_node_index());
            }
        }
    }

    return document;
}

#[cfg(test)]
mod tests {
    use super::{parse, Tag};

    #[test]
    fn test_parse() {
        let document = parse("<div><p>Hello</p>Happy</div>");
        assert_eq!(document.tags.len(), 4);
        assert_eq!(document.tags[0], Tag::Div);
        assert_eq!(document.texts[0], "");
        assert_eq!(document.tags[1], Tag::P);
        assert_eq!(document.texts[1], "");
        assert_eq!(document.parents[1], 0);
        assert_eq!(document.tags[2], Tag::Text);
        assert_eq!(document.texts[2], "Hello");
        assert_eq!(document.parents[2], 1);
        assert_eq!(document.tags[3], Tag::Text);
        assert_eq!(document.texts[3], "Happy");
        assert_eq!(document.parents[3], 0);
    }
}
