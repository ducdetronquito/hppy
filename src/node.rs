#[derive(Debug, PartialEq)]
enum Tag {
    Body,
    Div,
    P
}


struct Node {
    tag: Tag,
    id: i32,
}

impl Node {

    fn name(&self) -> &str {
        match self.tag {
            Tag::Body => "I am a body !",
            Tag::Div => "I am a div !",
            Tag::P => "I am a paragraph !",
        }
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_node_creation() {
        let node = Node {tag: Tag::Body, id: 2};

        assert_eq!(node.id, 2);
        assert_eq!(node.tag, Tag::Body);
    }

    #[test]
    fn test_node_name() {
        let node = Node {tag: Tag::Body, id: 2};

        assert_eq!(node.name(), "I am a body !");
    }
}
