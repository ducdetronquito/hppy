use crate::document::Document;
use crate::tag::{Tag};
use crate::parser::tokenizer::Tokenizer;

fn parse(content: &str) -> Document {
    let mut document = Document::new();
    let mut scopes = Vec::new();

    for token in Tokenizer::get_tokens(content) {
        if token.is_text() {
            document.push_text(&token.content);
            continue;
        }
        if token.is_opening_tag() {
            scopes.push(token.content.clone());
            document.push_tag(&token.content);
        } else if token.is_closing_tag() {
        }
    }

    return document;
}

#[cfg(test)]
mod tests {
    use super::{parse, Tag};

    #[test]
    fn test_parse() {
        let document = parse("<div>Hello Hppy</div>");
        assert_eq!(document.tags.len(), 2);
        assert_eq!(document.tags[0], Tag::Div);
        assert_eq!(document.texts[0], "");
        assert_eq!(document.tags[1], Tag::Text);
        assert_eq!(document.texts[1], "Hello Hppy");
    }
}
