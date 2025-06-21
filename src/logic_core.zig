const std = @import("std");
const core = @import("core.zig");
const HDLId = core.HDLId;
const ClkTrigger = core.EdgeTrigger;
const underlayingTypeCheck = core.ensurePacked;
const traits = @import("traits.zig");
const barazzesh = @import("barazzesh");
const hasTrait = barazzesh.hasTrait;
const GetTrait = barazzesh.getTrait;
const ModuleTrait = traits.ModuleTrait;
const WireTrait = traits.WireTrait;
const WritableWireTrait = traits.WritableWireTrait;

pub const WireAccess = enum(u1) { wire = 0, writableWire = 1 };
pub fn checkWireAccess(Wire: type) error{NotWire}!WireAccess {
    if (@typeInfo(Wire) != .@"struct" or
        !@hasDecl(Wire, "Type") or
        @TypeOf(Wire.Type) != type) return error.NotWire;
    if (hasTrait(Wire, WritableWireTrait)) return .writableWire;
    if (hasTrait(Wire, WireTrait)) return .wire;
    return error.NotWire;
}
pub fn checkWireType(Wire: type) error{NotWire}!type {
    _ = try checkWireAccess(Wire);
    return Wire.Type;
}

const SOME_PACKED_TYPES =
    .{ u6, i19, f32, packed struct { a: u1, b: u5 }, packed union { a: u1, b: u5 }, enum { a, b } };
const testing = std.testing;
test "wire-access detection" {
    inline for (SOME_PACKED_TYPES) |TT| {
        var internal = Internal(TT).init();
        var reg = Reg(TT, .posedge).init();
        const internalWire = GetTrait(@TypeOf(internal), WireTrait).init(&internal);
        const internalWWire = GetTrait(@TypeOf(internal), WritableWireTrait).init(&internal);
        const regWire = GetTrait(@TypeOf(reg), WireTrait).init(&reg);
        const regWWire = GetTrait(@TypeOf(reg), WritableWireTrait).init(&reg);

        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(internal)));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(reg)));

        try testing.expectEqual(WireAccess.wire, try checkWireAccess(@TypeOf(internalWire)));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(internalWWire)));

        try testing.expectEqual(WireAccess.wire, try checkWireAccess(@TypeOf(regWire)));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(regWWire)));

        try testing.expectError(error.NotWire, checkWireAccess(TT));
    }
}

pub fn ensureWireAccess(comptime W: type, comptime access: WireAccess) void {
    const acc = comptime checkWireAccess(W) catch core.compErrFmt("Expected a {s}, got a non-wire : {}", .{ @tagName(access), W });
    if (@intFromEnum(acc) < @intFromEnum(access))
        core.compErrFmt("Expected a {s}, got {s}", .{ @tagName(access), @tagName(acc) });
}
test "ensure wire-access" {
    var pin = Internal(u8).init();
    const pinWire = GetTrait(@TypeOf(pin), WireTrait).init(&pin);
    const pinWWire = GetTrait(@TypeOf(pin), WritableWireTrait).init(&pin);
    ensureWireAccess(@TypeOf(pin), .writableWire);
    ensureWireAccess(@TypeOf(pin), .wire);
    ensureWireAccess(@TypeOf(pinWWire), .writableWire);
    ensureWireAccess(@TypeOf(pinWWire), .wire);
    ensureWireAccess(@TypeOf(pinWire), .wire);
    // ensureWireAccess(@TypeOf(pinWire), .writableWire); // correct compErr
    // ensureWireAccess(u8, .writableWire); // correct compErr
}

test "check wire underlaying type" {
    inline for (SOME_PACKED_TYPES) |TT| {
        var internal = Internal(TT).init();
        var reg = Reg(TT, .posedge).init();
        const internalWire = GetTrait(@TypeOf(internal), WireTrait).init(&internal);
        const internalWWire = GetTrait(@TypeOf(internal), WritableWireTrait).init(&internal);
        const regWire = GetTrait(@TypeOf(reg), WireTrait).init(&reg);
        const regWWire = GetTrait(@TypeOf(reg), WritableWireTrait).init(&reg);

        try testing.expectError(error.NotWire, checkWireType(TT));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(internal)));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(reg)));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(internalWire)));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(regWire)));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(internalWWire)));
        try testing.expectEqual(TT, try checkWireType(@TypeOf(regWWire)));
    }
}
pub fn ensureSameType(comptime W1: type, comptime W2: type) void {
    const T1 = try checkWireType(W1);
    const T2 = try checkWireType(W2);
    comptime if (T1 != T2)
        core.compErrFmt("Missmatched wire types. {} != {}", .{ T1, T2 });
}

pub fn Reg(comptime UnderlayingType: type, comptime trigger: ClkTrigger) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        pub const Type = UnderlayingType;
        comptime trigger: ClkTrigger = trigger,
        value: ?UnderlayingType,
        shadow: ?UnderlayingType,
        id: HDLId(.Wire),
        const Self = @This();
        pub fn init() Self {
            return Self{
                .id = .newId(),
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
        pub fn getId(self: *const Self) HDLId(.Wire) {
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
    };
}
const PinType = enum(u2) { internal = 0, input = 1, output = 2, inout = 3 };
fn Pin(comptime UnderlayingType: type, comptime pin_type: PinType) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        pub const Type = UnderlayingType;
        pin_type: PinType,
        value: ?UnderlayingType,
        id: HDLId(.Wire),
        const Self = @This();
        pub fn init() Self {
            return Self{
                .id = .newId(),
                .value = null,
                .pin_type = pin_type,
            };
        }
        pub fn getId(self: *const Self) HDLId(.Wire) {
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
