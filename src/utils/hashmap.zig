const std = @import("std");
const HashMap = std.HashMap;
const rand = std.rand;


fn getEnumHashFunction(comptime Key: type) (fn (Key) u32) {
    return struct {
        fn hash(key: Key) u32 {
            comptime var rng = comptime rand.DefaultPrng.init(0);
            return std.hash_map.autoHash(@enumToInt(key), &rng.random, u32);
        }
    }.hash;
}


pub fn EnumHashMap(comptime Key: type, comptime Value: type) type {
    return HashMap(Key, Value, getEnumHashFunction(Key), std.hash_map.getAutoEqlFn(Key));
}
