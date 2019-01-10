use crate::document::Document;
use crate::node::Node;
use crate::parser::tokenizer::Tokenizer;

fn parse(content: &str) -> Document {
    let mut tokenizer = Tokenizer::new();
    let mut document = Document::new();

    for c in content.chars() {
        tokenizer.handle(c);

        if tokenizer.token_has_been_found() {
            let token_name = tokenizer.get_token_name();
            println!("Token: {}", token_name);
            let token_text_content = tokenizer.get_token_text_content();
            println!("Content: {}", token_text_content);
            let node = Node::new(token_name, token_text_content);
            document.add(node);
            tokenizer.clear_token();
        }
        // Maybe the token_stack should be managed by the parse function and not the parsing Context.
    }

    return document;
}

#[cfg(test)]
mod tests {
    use super::parse;

    #[test]
    fn test_parse() {
        let document = parse("<div><p>Hello Hppy</p></div>");
        println!("{:?}", document.nodes);
        assert_eq!(2 + 2, 4);
    }

}
