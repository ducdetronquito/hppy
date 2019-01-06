use crate::document::Document;
use crate::parser::context::Context;


fn parse(content: &str) -> Document {
    let mut context = Context::new();
    let document = Document::new();

    for c in content.chars() {
        context.handle(c);

        // Main idea on how to handle node creation.
        //
        // if context.node_is_pending() {
        //     tag_name = context.get_tag_name();
        //     content = context.get_content();
        //     attributs = context.get_attributes();
        //     document.add(tag_name, content, attributes);
        // }
        //
        // Maybe the token_stack should be managed by the parse function and not the parsing Context.
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
