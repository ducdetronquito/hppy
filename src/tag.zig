const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = @import("std").mem.Allocator;
const mem = std.mem;
const EnumHashMap = @import("utils/hashmap.zig").EnumHashMap;

pub const TagList = ArrayList(Tag);
pub const TagSet = EnumHashMap(Tag, void);


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

    pub fn get_self_closing_tags(allocator: *Allocator) !TagSet {
        var tags = TagSet.init(allocator);
        _ = try tags.put(Tag.Doctype, {});
        _ = try tags.put(Tag.Img, {});
        return tags;
    }
};
