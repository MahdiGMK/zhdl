const std = @import("std");
const core = @import("core.zig");
const HDLId = core.HDLId;
const ClkTrigger = core.ClkTrigger;
const underlayingTypeCheck = core.ensurePacked;

pub fn Wire(
    comptime Context: type,
    comptime UnderlayingType: type,
    comptime getIdfn: fn (ctx: Context) HDLId,
    comptime readfn: fn (ctx: Context) ?UnderlayingType,
) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        comptime UnderlayingType: type = UnderlayingType,
        context: Context,
        pub inline fn getId(self: *const @This()) HDLId {
            return getIdfn(self.context);
        }
        pub inline fn read(self: *const @This()) ?UnderlayingType {
            return readfn(self.context);
        }
    };
}
pub fn WritableWire(
    comptime Context: type,
    comptime UnderlayingType: type,
    comptime getIdfn: fn (ctx: Context) HDLId,
    comptime readfn: fn (ctx: Context) ?UnderlayingType,
    comptime writefn: fn (ctx: Context, value: ?UnderlayingType) void,
) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        comptime UnderlayingType: type = UnderlayingType,
        context: Context,
        const WireT = Wire(Context, UnderlayingType, getIdfn, readfn);
        pub inline fn getId(self: *const @This()) HDLId {
            return getIdfn(self.context);
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

pub const WireAccess = enum(bool) { wire, writableWire };
pub fn checkWireAccess(comptime W: type) error{notWire}!WireAccess {
    // var iwire = Internal(u1).init();
    // const DummyWire = @TypeOf(iwire.asWire());
    // const wire_tinfo = @typeInfo(DummyWire).@"struct";
    // const DummyWritableWire = @TypeOf(iwire.asWritableWire());
    // const wwire_tinfo = @typeInfo(DummyWritableWire).@"struct";

    const isWire =
        std.meta.hasFn(W, "getId") and
        std.meta.hasFn(W, "read");
    const isWWire = isWire and
        std.meta.hasFn(W, "write") and
        std.meta.hasFn(W, "asWire");
    return if (isWWire) WireAccess.writableWire else if (isWire) WireAccess.wire else error.notWire;
}

test "wire-access detection" {
    const testing = std.testing;
    inline for (.{ u6, i19, f32, f16, f64, packed struct { a: u1, b: u5 } }) |TT| {
        var internal = Internal(TT).init();
        var reg = Reg(TT, .posedge).init();

        try testing.expectEqual(WireAccess.wire, try checkWireAccess(@TypeOf(internal.asWire())));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(internal.asWritableWire())));

        try testing.expectEqual(WireAccess.wire, try checkWireAccess(@TypeOf(reg.asWire())));
        try testing.expectEqual(WireAccess.writableWire, try checkWireAccess(@TypeOf(reg.asWritableWire())));

        try testing.expectError(error.notWire, checkWireAccess(TT));
    }
}

pub fn Reg(comptime UnderlayingType: type, comptime trigger: ClkTrigger) type {
    underlayingTypeCheck(UnderlayingType);

    return struct {
        comptime trigger: ClkTrigger = trigger,
        value: ?UnderlayingType,
        shadow: ?UnderlayingType,
        id: HDLId,
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
        pub fn getId(self: *const Self) HDLId {
            return self.id;
        }
        pub fn read(self: *const Self) ?UnderlayingType {
            return self.value;
        }
        pub fn write(self: *Self, value: ?UnderlayingType) void {
            self.shadow = value;
        }
        const WireT = Wire(*const Self, UnderlayingType, getId, read);
        const WritableWireT = WritableWire(*Self, UnderlayingType, getId, read, write);
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
        pin_type: PinType,
        value: ?UnderlayingType,
        id: HDLId,
        const Self = @This();
        pub fn init() Self {
            return Self{
                .id = .newId(),
                .value = null,
                .pin_type = pin_type,
            };
        }
        pub fn getId(self: *const Self) HDLId {
            return self.id;
        }
        pub fn read(self: *const Self) ?UnderlayingType {
            return self.value;
        }
        pub fn write(self: *Self, value: ?UnderlayingType) void {
            self.value = value;
        }
        const WireT = Wire(*const Self, UnderlayingType, getId, read);
        const WritableWireT = WritableWire(*Self, UnderlayingType, getId, read, write);
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
