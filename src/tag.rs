#[derive(Clone, Debug, PartialEq)]
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
