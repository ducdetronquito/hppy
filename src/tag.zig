const mem = @import("std").mem;
const ArrayList = @import("std").ArrayList;

pub const TagList = ArrayList(Tag);

pub const Tag = enum {
    Body,
    Div,
    DocumentRoot,
    Doctype,
    P,
    Text,
    Undefined,

    pub fn from_name(name: []const u8) Tag {
        if (mem.eql_slice_u8(name, "body")) {
            return Tag.Body;
        }
        else if (mem.eql_slice_u8(name, "div")) {
            return Tag.Div;
        }
        else if (mem.eql_slice_u8(name, "DOCTYPE")) {
            return Tag.Doctype;
        }
        else if (mem.eql_slice_u8(name, "p")) {
            return Tag.P;
        }
        else if (mem.eql_slice_u8(name, "")) {
            return Tag.Text;
        }
        else {
            return Tag.Undefined;
        }
    }
};