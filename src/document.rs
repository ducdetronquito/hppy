use crate::tag::{Tag};

pub struct Document {
    pub tags: Vec<Tag>,
    pub texts: Vec<String>,
    pub relationships: Vec<i32>,
}

impl Document {
    pub fn new() -> Self {
        Document {
            tags: Vec::new(),
            texts: Vec::new(),
            relationships: Vec::new(),
        }
    }

    pub fn push_tag(&mut self, tag_name: &str) {
        self.tags.push(Tag::from_name(tag_name));
        self.texts.push("".to_string());
    }

    pub fn push_text(&mut self, text: &str) {
        self.tags.push(Tag::Text);
        self.texts.push(text.to_string());
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_push_tag() {
        let mut document = Document::new();
        document.push_tag("div");
        assert_eq!(document.tags.len(), 1);
        assert_eq!(document.tags[0], Tag::Div);
        assert_eq!(document.texts[0], "");
    }

    #[test]
    fn test_push_text() {
        let mut document = Document::new();
        document.push_text("Hello Hppy!");
        assert_eq!(document.tags.len(), 1);
        assert_eq!(document.tags[0], Tag::Text);
        assert_eq!(document.texts[0], "Hello Hppy!");
    }
}
