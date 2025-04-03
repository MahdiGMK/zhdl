const std = @import("std");
const core = @import("core.zig");
const HDLId = core.HDLId;
const ClkTrigger = core.ClkTrigger;
const underlayingTypeCheck = core.ensurePacked;

pub fn Wire(
    comptime Context: type,
    comptime UnderlayingType: type,
    comptime getIdfn: fn (self: Context) HDLId,
    comptime registerfn: fn (self: Context, ctx: anytype) void,
    comptime readfn: fn (self: Context) ?UnderlayingType,
) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        const Type = UnderlayingType;
        context: Context,
        pub inline fn getId(self: *const @This()) HDLId {
            return getIdfn(self.context);
        }
        pub inline fn register(self: *const @This(), ctx: anytype) void {
            return registerfn(self.context, ctx);
        }
        pub inline fn read(self: *const @This()) ?UnderlayingType {
            return readfn(self.context);
        }
    };
}
pub fn WritableWire(
    comptime Context: type,
    comptime UnderlayingType: type,
    comptime getIdfn: fn (self: Context) HDLId,
    comptime registerfn: fn (self: Context, ctx: anytype) void,
    comptime readfn: fn (self: Context) ?UnderlayingType,
    comptime writefn: fn (self: Context, value: ?UnderlayingType) void,
) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        const Type = UnderlayingType;
        context: Context,
        const WireT = Wire(Context, UnderlayingType, getIdfn, registerfn, readfn);
        pub inline fn getId(self: *const @This()) HDLId {
            return getIdfn(self.context);
        }
        pub inline fn register(self: *const @This(), ctx: anytype) void {
            return registerfn(self, ctx);
        }
        pub inline fn read(self: *const @This()) ?UnderlayingType {
            return readfn(self.context);
        }
        pub inline fn write(self: *@This(), value: ?UnderlayingType) void {
            return writefn(self.context, value);
        }
        pub inline fn asWire(self: *const @This()) WireT {
            return WireT{ .context = self.context };
        }
    };
}

pub const WireAccess = enum(u1) { wire, writableWire };
pub fn checkWireAccess(comptime W: type) error{notWire}!WireAccess {
    // var iwire = Internal(u1).init();
    // const DummyWire = @TypeOf(iwire.asWire());
    // const wire_tinfo = @typeInfo(DummyWire).@"struct";
    // const DummyWritableWire = @TypeOf(iwire.asWritableWire());
    // const wwire_tinfo = @typeInfo(DummyWritableWire).@"struct";

    const isWire =
        @typeInfo(W) == .@"struct" and
        @hasDecl(W, "Type") and
        std.meta.hasFn(W, "getId") and
        std.meta.hasFn(W, "register") and
        std.meta.hasFn(W, "read");
    const isWWire = isWire and
        std.meta.hasFn(W, "write") and
        std.meta.hasFn(W, "asWire");
    return if (isWWire) WireAccess.writableWire else if (isWire) WireAccess.wire else error.notWire;
}

const SOME_PACKED_TYPES =
    .{ u6, i19, f32, packed struct { a: u1, b: u5 }, packed union { a: u1, b: u5 }, enum { a, b } };
const testing = std.testing;
test "wire-access detection" {
    inline for (SOME_PACKED_TYPES) |TT| {
        var internal = Internal(TT).init();
        var reg = Reg(TT, .posedge).init();

        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(internal)));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(internal)));

        try testing.expectEqual(WireAccess.wire, try checkWireAccess(@TypeOf(internal.asWire())));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(internal.asWritableWire())));

        try testing.expectEqual(WireAccess.wire, try checkWireAccess(@TypeOf(reg.asWire())));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(reg.asWritableWire())));

        try testing.expectError(error.notWire, checkWireAccess(TT));
    }
}

pub fn ensureWireAccess(comptime W: type, comptime access: WireAccess) void {
    const acc = comptime checkWireAccess(W) catch core.compErrFmt("Expected a {s}, got a non-wire : {}", .{ @tagName(access), W });
    if (@intFromEnum(acc) < @intFromEnum(access))
        core.compErrFmt("Expected a {s}, got {s}", .{ @tagName(access), @tagName(acc) });
}
test "ensure wire-access" {
    var pin = Internal(u8).init();
    ensureWireAccess(@TypeOf(pin), .writableWire);
    ensureWireAccess(@TypeOf(pin), .wire);
    ensureWireAccess(@TypeOf(pin.asWritableWire()), .writableWire);
    ensureWireAccess(@TypeOf(pin.asWritableWire()), .wire);
    ensureWireAccess(@TypeOf(pin.asWire()), .wire);
    // ensureWireAccess(@TypeOf(pin.asWire()), .writableWire); correct compErr
    // ensureWireAccess(u8, .writableWire); correct compErr
}

pub fn checkWireType(comptime W: type) error{notWire}!type {
    _ = try checkWireAccess(W);
    return W.Type;
}
test "check wire underlaying type" {
    inline for (SOME_PACKED_TYPES) |TT| {
        var internal = Internal(TT).init();
        var reg = Reg(TT, .posedge).init();
        try testing.expectError(error.notWire, checkWireType(TT));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(internal)));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(reg)));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(internal.asWire())));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(reg.asWire())));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(internal.asWritableWire())));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(reg.asWritableWire())));
    }
}

pub fn Reg(comptime UnderlayingType: type, comptime trigger: ClkTrigger) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        const Type = UnderlayingType;
        comptime trigger: ClkTrigger = trigger,
        value: ?UnderlayingType,
        shadow: ?UnderlayingType,
        id: HDLId,
        const Self = @This();
        pub fn init() Self {
            return Self{
                .id = .newId(.Reg),
                .value = null,
                .shadow = null,
            };
        }
        inline fn update(self: *Self) void {
            self.value = self.shadow;
        }
        pub inline fn clkTick(self: *Self, tick: ClkTrigger) void {
            if ((tick & self.trigger) != 0) self.update();
        }
        pub fn getId(self: *const Self) HDLId {
            return self.id;
        }
        pub fn register(self: *const Self, ctx: anytype) void {
            ctx.registerElement(self);
        }
        pub fn read(self: *const Self) ?UnderlayingType {
            return self.value;
        }
        pub fn write(self: *Self, value: ?UnderlayingType) void {
            self.shadow = value;
        }
        const WireT = Wire(*const Self, UnderlayingType, getId, register, read);
        const WritableWireT = WritableWire(*Self, UnderlayingType, getId, register, read, write);
        pub inline fn asWire(self: *Self) WireT {
            return WireT{ .context = self };
        }
        pub inline fn asWritableWire(self: *Self) WritableWireT {
            return WritableWireT{ .context = self };
        }
    };
}
const PinType = enum(u2) { internal = 0, input = 1, output = 2, inout = 3 };
fn Pin(comptime UnderlayingType: type, comptime pin_type: PinType) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        const Type = UnderlayingType;
        pin_type: PinType,
        value: ?UnderlayingType,
        id: HDLId,
        const Self = @This();
        pub fn init() Self {
            return Self{
                .id = .newId(.Pin),
                .value = null,
                .pin_type = pin_type,
            };
        }
        pub fn getId(self: *const Self) HDLId {
            return self.id;
        }
        pub fn register(self: *const Self, ctx: anytype) void {
            ctx.registerElem(self);
        }
        pub fn read(self: *const Self) ?UnderlayingType {
            return self.value;
        }
        pub fn write(self: *Self, value: ?UnderlayingType) void {
            self.value = value;
        }
        const WireT = Wire(*const Self, UnderlayingType, getId, register, read);
        const WritableWireT = WritableWire(*Self, UnderlayingType, getId, register, read, write);
        pub inline fn asWire(self: *const Self) WireT {
            return WireT{ .context = self };
        }
        pub inline fn asWritableWire(self: *Self) WritableWireT {
            return WritableWireT{ .context = self };
        }
    };
}
pub fn Internal(comptime UnderlayingType: type) type {
    return Pin(UnderlayingType, .internal);
}
pub fn Input(comptime UnderlayingType: type) type {
    return Pin(UnderlayingType, .input);
}
pub fn Output(comptime UnderlayingType: type) type {
    return Pin(UnderlayingType, .output);
}
pub fn Inout(comptime UnderlayingType: type) type {
    return Pin(UnderlayingType, .inout);
}
