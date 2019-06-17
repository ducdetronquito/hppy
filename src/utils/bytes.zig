const mem = @import("std").mem;


pub fn equals(a: []const u8, b: []const u8) bool {
    return mem.eql_slice_u8(a, b);
}