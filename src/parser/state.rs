#[derive(Debug, PartialEq)]
pub enum State {
    Done,
    ReadAttributes,
    ReadClosingComment,
    ReadClosingCommentDash,
    ReadClosingTagName,
    ReadCommentContent,
    ReadContent,
    ReadDoctype,
    ReadOpeningCommentDash,
    ReadOpeningCommentOrDoctype,
    ReadOpeningTagName,
    ReadTagName,
    ReadText,
    SeekOpeningTag,
}
