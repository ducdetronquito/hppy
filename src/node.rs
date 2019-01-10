#[derive(Debug, PartialEq)]
enum Tag {
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
            _ => Tag::Undefined
        }
    }
}

#[derive(Debug)]
pub struct Node {
    tag: Tag,
    text_content: String,
    id: i32,
}

impl Node {

    pub fn new(tag_name: &str, text_content: &str) -> Self {
        Node {
            tag: Tag::from_name(tag_name),
            text_content: text_content.to_string(),
            id: -1
        }
    }
}


#[cfg(test)]
mod tests {
    use super::{Node, Tag};

    #[test]
    fn test_new_node() {
        let node = Node::new("div", "Hello Hppy!");
        assert_eq!(node.tag, Tag::Div);
        assert_eq!(node.text_content, "Hello Hppy!")
    }
}
