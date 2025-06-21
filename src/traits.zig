const std = @import("std");
const barazzesh = @import("barazzesh");
const getTrait = barazzesh.getTrait;
const hasTrait = barazzesh.hasTrait;
const core = @import("core.zig");
const HDLId = core.HDLId;

pub fn ModuleTrait(This: type) type {
    return enum {
        register,
        pub fn Trait(
            comptime registerfn: fn (self: *const This, ctx: anytype) void,
        ) type {
            return struct {
                self: *const This,
                pub inline fn init(self: *const This) @This() {
                    return .{ .self = self };
                }
                pub inline fn register(self: *const @This(), ctx: anytype) void {
                    registerfn(self.self, ctx);
                }
            };
        }
    };
}
pub fn WireTrait(This: type) type {
    if (!@hasDecl(This, "Type") or @TypeOf(This.Type) != type) {
        @compileLog(@TypeOf(This.Type));
        @compileLog(This.Type);
        core.compErrFmt("Expected '{any}' to express it's underlaying type as 'const Type'", .{This});
    }
    const UnderlayingType = This.Type;
    core.ensurePacked(UnderlayingType);
    return enum {
        getId,
        read,
        pub fn Trait(
            comptime getIdfn: fn (self: *const This) HDLId(.Wire),
            comptime readfn: fn (self: *const This) ?UnderlayingType,
        ) type {
            return struct {
                pub const ModuleT = getTrait(This, ModuleTrait);
                self: *const This,
                module_t: ModuleT,
                pub const Type = UnderlayingType;
                pub fn init(self: *const This) @This() {
                    return .{ .self = self, .module_t = .init(self) };
                }
                pub fn register(self: *const @This(), ctx: anytype) void {
                    return @call(.always_inline, self.module_t.register, .{ctx});
                }
                pub fn getId(self: *const @This()) HDLId(.Wire) {
                    return @call(.always_inline, getIdfn, .{self.self});
                }
                pub fn read(self: *const @This()) ?UnderlayingType {
                    return @call(.always_inline, readfn, .{self.self});
                }
            };
        }
    };
}
pub fn WritableWireTrait(This: type) type {
    if (!@hasDecl(This, "Type") or @TypeOf(This.Type) != type) {
        core.compErrFmt("Expected '{any}' to express it's underlaying type as 'pub const Type'", .{This});
    }
    const UnderlayingType = This.Type;
    core.ensurePacked(UnderlayingType);
    return enum {
        write,
        pub fn Trait(
            comptime writefn: fn (self: *This, value: ?UnderlayingType) void,
        ) type {
            return struct {
                pub const WireT = getTrait(This, WireTrait);
                self: *This,
                wire_t: WireT,
                pub const Type = UnderlayingType;
                pub fn init(self: *This) @This() {
                    return .{ .self = self, .wire_t = .init(self) };
                }
                pub fn register(self: *const @This(), ctx: anytype) void {
                    return @call(.always_inline, self.wire_t.module_t.register, .{ctx});
                }
                pub fn getId(self: *const @This()) HDLId(.Wire) {
                    return @call(.always_inline, self.wire_t.getId, .{});
                }
                pub fn read(self: *const @This()) ?UnderlayingType {
                    return @call(.always_inline, self.wire_t.read, .{});
                }
                pub fn write(self: *@This(), value: ?UnderlayingType) void {
                    return @call(.always_inline, writefn, .{ self.self, value });
                }
            };
        }
    };
}
