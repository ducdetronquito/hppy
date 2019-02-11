use crate::document::Document;
use crate::node::{Node, Tag};
use crate::parser::tokenizer::Tokenizer;

fn parse(content: &str) -> Document {
    let mut document = Document::new();
    let mut scopes = Vec::new();

    for token in Tokenizer::get_tokens(content) {
        if token.is_text() {
            document.push_text(&token.content);
            continue;
        }
        let node = Node::tag(&token.content);
        if token.is_opening_tag() {
            let scope = node.clone();
            scopes.push(scope);
            document.push(node);
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
        assert_eq!(document.nodes.len(), 2);
        assert_eq!(document.nodes[0].tag, Tag::Div);
        assert_eq!(document.nodes[0].text_content, "");
        assert_eq!(document.nodes[1].tag, Tag::Text);
        assert_eq!(document.nodes[1].text_content, "Hello Hppy");
    }
}
