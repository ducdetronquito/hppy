const std = @import("std");


pub const AttributeMap = std.AutoHashMap([]u8, []u8);
pub const AttributesList = std.ArrayList(AttributeMap);
