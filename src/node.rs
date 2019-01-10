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
    id: i32,
}

impl Node {
    pub fn tag(tag_name: &str) -> Self {
        Node {
            tag: Tag::from_name(tag_name),
            text_content: String::new(),
            id: -1,
        }
    }

    pub fn text(text_content: &str) -> Self {
        Node {
            tag: Tag::Text,
            text_content: text_content.to_string(),
            id: -1,
        }
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
