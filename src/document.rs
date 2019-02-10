use crate::node::{Node, Tag};

pub struct Document {
    pub nodes: Vec<Node>,
}

impl Document {
    pub fn new() -> Self {
        Document { nodes: Vec::new() }
    }

    pub fn push_tag(&mut self, tag_name: &str) {
        self.nodes.push(Node::tag(tag_name));
    }

    pub fn push_text(&mut self, text_content: &str) {
        self.nodes.push(Node::text(text_content));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_push_tag() {
        let mut document = Document::new();
        document.push_tag("div");
        assert_eq!(document.nodes.len(), 1);
        assert_eq!(document.nodes[0].tag, Tag::Div);
    }

    #[test]
    fn test_push_text() {
        let mut document = Document::new();
        document.push_text("Hello Hppy!");
        assert_eq!(document.nodes.len(), 1);
        assert_eq!(document.nodes[0].tag, Tag::Text);
        assert_eq!(document.nodes[0].text_content, "Hello Hppy!");
    }
}
