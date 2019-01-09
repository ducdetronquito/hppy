use crate::document::Document;
use crate::parser::tokenizer::Tokenizer;

fn parse(content: &str) -> Document {
    let mut tokenizer = Tokenizer::new();
    let document = Document::new();

    for c in content.chars() {
        tokenizer.handle(c);

        if tokenizer.token_has_been_found() {
            let token_name = tokenizer.get_token_name();
            println!("Token: {}", token_name);
            let token_text_content = tokenizer.get_token_text_content();
            println!("Content: {}", token_text_content);
            tokenizer.clear_token();
        }

        // Main idea on how to handle node creation.
        //
        // if context.token_has_been_found() {
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
