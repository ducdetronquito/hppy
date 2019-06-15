const mem = @import("std").mem;
const ArrayList = @import("std").ArrayList;

pub const Bytes = struct {
    pub fn equals(a: []const u8, b: []const u8) bool {
        return mem.eql_slice_u8(a, b);
    }
};


pub const BytesList = ArrayList([]u8);
