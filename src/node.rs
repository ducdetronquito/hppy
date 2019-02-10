#[derive(Debug, PartialEq)]
pub enum Tag {
    Body,
    Div,
    P,
    Text,
    Undefined,
}

impl Tag {
    pub fn from_name(name: &str) -> Self {
        match name {
            "body" => Tag::Body,
            "div" => Tag::Div,
            "p" => Tag::P,
            "" => Tag::Text,
            _ => Tag::Undefined,
        }
    }
}

#[derive(Debug)]
pub struct Node {
    pub tag: Tag,
    pub text_content: String,
    pub index: i32,
}

impl Node {
    fn new(tag: Tag, text_content: &str) -> Self {
        Node {
            tag: tag,
            text_content: text_content.to_string(),
            index: -1,
        }
    }
    pub fn tag(tag_name: &str) -> Self {
        Node::new(Tag::from_name(tag_name), "")
    }

    pub fn text(text_content: &str) -> Self {
        Node::new(Tag::Text, text_content)
    }
}

#[cfg(test)]
mod tests {
    use super::{Node, Tag};

    #[test]
    fn test_create_a_tag_node() {
        let node = Node::tag("div");
        assert_eq!(node.tag, Tag::Div);
        assert_eq!(node.text_content, "")
    }

    #[test]
    fn test_create_a_text_node() {
        let node = Node::text("Hello Hppy!");
        assert_eq!(node.tag, Tag::Text);
        assert_eq!(node.text_content, "Hello Hppy!")
    }
}
