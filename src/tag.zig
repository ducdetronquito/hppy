const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const mem = std.mem;
const ArrayList = std.ArrayList;

pub const TagList = ArrayList(Tag);


pub const Tag = enum {
    Body,
    Div,
    DocumentRoot,
    Doctype,
    Img,
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
        else if (mem.eql_slice_u8(name, "img")) {
            return Tag.Img;
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

    pub fn get_self_closing_tags(allocator: *Allocator) !TagList {
        var tags = TagList.init(allocator);
        try tags.append(Tag.Doctype);
        try tags.append(Tag.Img);
        return tags;
    }

    pub fn is_in(self: Tag, values: *TagList) bool {
        for (values.toSlice()) |tag| {
            if (self == tag) {
                return true;
            }
        }
        return false;
    }
};
