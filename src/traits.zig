const std = @import("std");
const barazzesh = @import("barazzesh");
const getTrait = barazzesh.getTrait;
const hasTrait = barazzesh.hasTrait;
const core = @import("core.zig");
const HDLId = core.HDLId;

pub fn ModuleTrait(This: type) type {
    return enum {
        getId,
        register,
        fn Trait(
            comptime getIdfn: fn (self: This) HDLId(.Wire),
            comptime registerfn: fn (self: This, ctx: anytype) void,
        ) type {
            return struct {
                self: *const This,
                inline fn init(self: *const This) @This() {
                    return .{ .self = self };
                }
                inline fn getId(self: *const @This()) HDLId(.Wire) {
                    return getIdfn(self.self);
                }
                inline fn register(self: *const @This(), ctx: anytype) void {
                    registerfn(self.self, ctx);
                }
            };
        }
    };
}
pub fn WireTrait(This: type) type {
    if (!@hasDecl(This, "Type") or @TypeOf(@field(This, "Type")) != type) {
        core.compErrFmt("Expected '{any}' to express it's underlaying type as 'const Type'", .{This});
    }
    const UnderlayingType = This.Type;
    core.ensurePacked(UnderlayingType);
    return enum {
        read,
        fn Trait(
            comptime readfn: fn (self: This) ?UnderlayingType,
        ) type {
            return struct {
                const ModuleT = getTrait(This, ModuleTrait);
                self: *const This,
                module_t: ModuleT,
                const Type = UnderlayingType;
                inline fn init(self: *const This) @This() {
                    return .{ .self = self, .module_t = .init(self) };
                }
                inline fn read(self: *const @This()) ?UnderlayingType {
                    return readfn(self.self);
                }
            };
        }
    };
}
pub fn WritableWireTrait(This: type) type {
    if (!@hasDecl(This, "Type") or @TypeOf(@field(This, "Type")) != type) {
        core.compErrFmt("Expected '{any}' to express it's underlaying type as 'const Type'", .{This});
    }
    const UnderlayingType = This.Type;
    core.ensurePacked(UnderlayingType);
    return enum {
        write,
        fn Trait(
            comptime writefn: fn (self: This, value: ?UnderlayingType) void,
        ) type {
            return struct {
                const WireT = getTrait(This, WireTrait(This, UnderlayingType));
                self: *const This,
                wire_t: WireT,
                const Type = UnderlayingType;
                inline fn init(self: *const This) @This() {
                    return .{ .self = self, .wire_t = .init(self) };
                }
                inline fn read(self: *const @This()) ?UnderlayingType {
                    return self.wire_t.read();
                }
                inline fn write(self: *const @This(), value: ?UnderlayingType) void {
                    return writefn(self.self, value);
                }
            };
        }
    };
}
pub const WireAccess = enum(u1) { wire, writableWire };
pub fn checkWireAccess(Wire: type) error{NotWire}!WireAccess {
    if (hasTrait(Wire, WritableWireTrait)) return .writableWire;
    if (hasTrait(Wire, WireTrait)) return .wire;
    return error.NotWire;
}
pub fn checkWireType(Wire: type) type {
    return getTrait(Wire, WireTrait).Type;
}

test "WireTrait" {}
