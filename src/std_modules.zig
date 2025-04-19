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

// pub fn DLatch(ctx: anytype, d: anytype, en: anytype, q: anytype) void {
//     logic_core.ensureWireAccess(d, .wire);
//     logic_core.ensureWireAccess(en, .wire);
//     logic_core.ensureWireAccess(q, .writableWire);
// }
//
// pub fn WritableCompositeWire(Wires: type) type {
//     _ = Wires;
// }
// pub fn CompositeWire(Wires: type) type {
//     _ = Wires;
// }
// pub fn checkCompositeWireAccess(Wires: type) logic_core.WireAccess {
//     switch (@typeInfo(Wires)) {
//         .@"struct" => {},
//         else => @compileError("Incompatible {wires} field"),
//     }

//     const fields = @typeInfo(Wires).@"struct".fields;
//     var resulting_access = logic_core.WireAccess.writableWire;
//     inline for (fields) |field| {
//         const wireAccess = comptime logic_core.checkWireAccess(field.type) catch @compileError("{wires} has a non-wire");
//         if (wireAccess == .wire) resulting_access = .wire;
//     }
// }
// /// turns Struct-of-Wires to Wire-of-Structs
// pub fn composeWires(wires: anytype) switch (checkCompositeWireAccess(@TypeOf(wires))) {
//     .wire => CompositeWire(@TypeOf(wires)),
//     .writableWire => WritableCompositeWire(@TypeOf(wires)),
// } {}

// test "compose-wires" {
//     var a = logic_core.Internal(u16).init();
//     var b = logic_core.Internal(u16).init();
//     var c = logic_core.Internal(u16).init();
//     var d = logic_core.Internal(u16).init();
//     composeWires(.{ .a = a.asWire(), .b = b.asWire(), .c = c.asWritableWire(), .d = d.asWritableWire() });
// }

// /// turns Wire-of-Structs to Structs-of-Wire
// pub fn decomposeWire(comptime wire: anytype) void {
//     const UnderlayingType: type = wire.UnderlayingType;
//     _ = UnderlayingType;
// }
