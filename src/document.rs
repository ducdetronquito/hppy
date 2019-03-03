use crate::parser::parser;
use crate::tag::{Tag};


pub struct Document {
    pub tags: Vec<Tag>,
    pub texts: Vec<String>,
    pub parents: Vec<i32>,
}

impl Document {
    pub fn new() -> Self {
        Document {
            tags: Vec::new(),
            texts: Vec::new(),
            parents: Vec::new(),
        }
    }

    pub fn push_tag(&mut self, tag_name: &str, parent_index: i32) {
        self.tags.push(Tag::from_name(tag_name));
        self.texts.push("".to_string());
        self.parents.push(parent_index);
    }

    pub fn push_text(&mut self, text: &str, parent_index: i32) {
        self.tags.push(Tag::Text);
        self.texts.push(text.to_string());
        self.parents.push(parent_index);
    }

    pub fn get_last_node_index(& self) -> i32 {
        self.tags.len() as i32
    }

    pub fn from_string(content: &str) -> Self {
        parser::parse(content)
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_push_tag() {
        let mut document = Document::new();
        document.push_tag("div", -1);
        assert_eq!(document.tags.len(), 1);
        assert_eq!(document.tags[0], Tag::Div);
        assert_eq!(document.texts[0], "");
    }

    #[test]
    fn test_push_text() {
        let mut document = Document::new();
        document.push_text("Hello Hppy!", -1);
        assert_eq!(document.tags.len(), 1);
        assert_eq!(document.tags[0], Tag::Text);
        assert_eq!(document.texts[0], "Hello Hppy!");
    }
}
