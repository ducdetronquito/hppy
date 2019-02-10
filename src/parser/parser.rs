use crate::document::Document;
use crate::node::Tag;
use crate::parser::tokenizer::Tokenizer;

fn parse(content: &str) -> Document {
    let mut document = Document::new();

    for token in Tokenizer::get_tokens(content) {
        if token.is_tag() {
            document.push_tag(&token.content);
        } else {
            document.push_text(&token.content);
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
        assert_eq!(document.nodes.len(), 2);
        assert_eq!(document.nodes[0].tag, Tag::Div);
        assert_eq!(document.nodes[0].text_content, "");
        assert_eq!(document.nodes[1].tag, Tag::Text);
        assert_eq!(document.nodes[1].text_content, "Hello Hppy");
    }
}
