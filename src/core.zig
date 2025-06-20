const std = @import("std");
pub const HDLElemType = enum(u4) { Circuit, Wire };

pub fn HDLId(comptime ty: HDLElemType) type {
    return packed struct {
        ty: HDLElemType,
        value: u60 = 0,
        const Self = @This();
        pub fn valid(self: *Self) bool {
            return self.value != 0 and self.ty;
        }
        pub fn newId() Self {
            const State = struct {
                var global_id_counter: u60 = 0;
            };
            State.global_id_counter += 1;
            return Self{ .ty = ty, .value = State.global_id_counter };
        }
    };
}
pub const EdgeTrigger = enum(u2) { none = 0, posedge = 1, negedge = 2, both = 3 };

pub const Time = struct {
    val_in_ps: usize,
    pub fn micro(val: usize) Time {
        return .{ .val_in_ps = val * 1000_000 };
    }
    pub fn nano(val: usize) Time {
        return Time{ .val_in_ps = val * 1000 };
    }
    pub fn pico(val: usize) Time {
        return .{ .val_in_ps = val };
    }
    pub fn toPico(self: *Time) usize {
        return self.val_in_ps;
    }
    pub fn toNano(self: *Time) usize {
        return (self.val_in_ps + 999) / 1000;
    }
    pub fn toMicro(self: *Time) usize {
        return (self.val_in_ps + 999_999) / 1000_000;
    }
};

pub inline fn ensurePacked(T: type) void {
    const tinfo = @typeInfo(T);
    sw: switch (tinfo) {
        .@"struct" => |info| {
            comptime var expected_bit_count: usize = 0;
            inline for (info.fields) |field| {
                ensurePacked(field.type);
                expected_bit_count += @bitSizeOf(field.type);
            }
            if (expected_bit_count != @bitSizeOf(T)) break :sw;
            return;
        },
        .@"enum" => |info| {
            ensurePacked(info.tag_type);
            return;
        },
        .@"union" => |info| {
            if (info.layout == .@"packed") return;
            @compileError("TODO");
        },
        .array => |info| {
            ensurePacked(info.child);
            if (@bitSizeOf(T) != info.len * @bitSizeOf(info.child)) break :sw;
            return;
        },
        .optional => |info| {
            ensurePacked(info.child);
            if (@bitSizeOf(T) != 1 + @bitSizeOf(info.child)) break :sw;
            return;
        },
        .bool => {
            if (@bitSizeOf(T) != 1) break :sw; // comptime_int pretty much never will be
            return;
        },
        .int => |info| {
            if (@bitSizeOf(T) != info.bits) break :sw;
            return;
        },
        .float => |info| {
            if (@bitSizeOf(T) != info.bits) break :sw;
            return;
        },
        .vector => |info| {
            ensurePacked(info.child);
            if (@bitSizeOf(T) != info.len * @bitSizeOf(info.child)) break :sw;
            return;
        },
        else => break :sw,
    }
    compErrFmt("The given type({}) has holes in memory layout. Unsupported!", .{T});
}

pub fn compErrFmt(comptime fmt: []const u8, args: anytype) void {
    @compileError(std.fmt.comptimePrint(fmt, args));
}

test "packed struct has no holes" {
    ensurePacked(packed struct { a: u1, b: u2 });
    ensurePacked(packed struct { a: u2, b: u3 });
    ensurePacked(packed struct { a: enum(u2) { a, b, c, d }, b: u3 });
    ensurePacked(packed struct { a: enum(u3) { a, b, c, d }, b: u3 });
}
test "aligned unpacked struct has no holes" {
    ensurePacked(struct { a: u384, b: u128 });
    ensurePacked(struct { a: u8, b: u8 });
    ensurePacked(struct { a: u16, b: u16 });
    ensurePacked(struct { a: u32, b: u32 });
    ensurePacked(struct { a: u64, b: u64 });
}
test "enum has no holes" {
    ensurePacked(enum { a, b });
    ensurePacked(enum { a, b, c });
    ensurePacked(enum { a, b, c, d });
    ensurePacked(enum { a, b, c, d, e });
    ensurePacked(enum { a, b, c, d, e, f, g, h, i });
}
test "packed union has no holes" {
    ensurePacked(packed union { a: u1, b: u2 });
}
