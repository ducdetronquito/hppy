use crate::node::Node;

pub struct Document {
    pub nodes: Vec<Node>,
}

impl Document {
    pub fn new() -> Self {
        Document { nodes: Vec::new() }
    }

    pub fn add(&mut self, node: Node) {
        self.nodes.push(node);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        let mut document = Document::new();
        let node = Node::new("div", "");
        document.add(node);
        assert_eq!(document.nodes.len(), 1);
    }
}
