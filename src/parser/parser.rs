use crate::document::Document;
use crate::parser::context::Context;


fn parse(content: &str) -> Document {
    let mut context = Context::new();
    let document = Document::new();

    for c in content.chars() {
        context.handle(c);
    }

    return document;
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse() {
        parse("<div><p>Hello Hppy</p></div>");
        assert_eq!(2 + 2, 4);
    }

}
