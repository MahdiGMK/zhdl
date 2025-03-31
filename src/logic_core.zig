const std = @import("std");
const core = @import("core.zig");
const HDLId = core.HDLId;
const ClkTrigger = core.ClkTrigger;

pub fn Wire(
    comptime Context: type,
    comptime UnderlayingType: type,
    comptime getIdfn: fn (ctx: Context) HDLId,
    comptime readfn: fn (ctx: Context) ?UnderlayingType,
) type {
    return struct {
        context: Context,
        pub inline fn getId(self: *@This()) HDLId {
            return getIdfn(self.context);
        }
        pub inline fn read(self: *@This()) ?UnderlayingType {
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
    return struct {
        context: Context,
        const WireT = Wire(Context, UnderlayingType, getIdfn, readfn);
        pub inline fn getId(self: *@This()) HDLId {
            return getIdfn(self.context);
        }
        pub inline fn read(self: *@This()) ?UnderlayingType {
            return readfn(self.context);
        }
        pub inline fn write(self: *@This(), value: ?UnderlayingType) void {
            return writefn(self.context, value);
        }
        pub inline fn asWire(self: *@This()) WireT {
            return WireT{ .context = self.context };
        }
    };
}

/// takes some number of wires: .{wire0, wire1, wire2, ...}
/// and merges them into a single wire
pub fn compositeWire(comptime wires: anytype) type {
    _ = wires;
    return struct {};
}

pub fn Reg(comptime UnderlayingType: type, comptime trigger: ClkTrigger) type {
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
        pub inline fn getId(self: *Self) HDLId {
            return self.id;
        }
        pub inline fn read(self: *Self) ?UnderlayingType {
            return self.value;
        }
        pub inline fn write(self: *Self, value: ?UnderlayingType) void {
            self.shadow = value;
        }
        const WireT = Wire(*Self, UnderlayingType, getId, read);
        const WritableWireT = WritableWire(*Self, UnderlayingType, getId, read, write);
        pub inline fn asWire(self: *Self) WireT {
            return WireT{ .context = self };
        }
        pub inline fn asWritableWire(self: *Self) WireT {
            return WritableWireT{ .context = self };
        }
    };
}
const PinType = enum(u2) { internal = 0, input = 1, output = 2, inout = 3 };
fn Pin(comptime UnderlayingType: type, comptime pin_type: PinType) type {
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
        pub inline fn getId(self: *Self) HDLId {
            return self.id;
        }
        pub inline fn read(self: *Self) ?UnderlayingType {
            return self.value;
        }
        pub inline fn write(self: *Self, value: ?UnderlayingType) void {
            self.value = value;
        }
        const WireT = Wire(*Self, UnderlayingType, getId, read);
        const WritableWireT = WritableWire(*Self, UnderlayingType, getId, read, write);
        pub inline fn asWire(self: *Self) WireT {
            return WireT{ .context = self };
        }
        pub inline fn asWritableWire(self: *Self) WireT {
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
