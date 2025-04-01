const std = @import("std");
const core = @import("core.zig");
const logic_core = @import("logic_core.zig");
const module_core = @import("module_core.zig");
pub const Wire =
    logic_core.Wire;
pub const WritableWire =
    logic_core.WritableWire;
const CTX =
    module_core.CTX;

/// turns Struct-of-Wires to Wire-of-Structs
pub fn composeWires(comptime wires: anytype) void {
    const tinfo = @typeInfo(@TypeOf(wires));
    switch (tinfo) {}
}

/// turns Wire-of-Structs to Structs-of-Wire
pub fn decomposeWire(comptime wire: anytype) void {
    const UnderlayingType: type = wire.UnderlayingType;
    _ = UnderlayingType;
}
