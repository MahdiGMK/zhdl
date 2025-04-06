const std = @import("std");
const testing = std.testing;
pub const core = @import("core.zig");
pub const logic_core = @import("logic_core.zig");
pub const HDLId = core.HDLId;
pub const Wire =
    logic_core.Wire;
pub const WritableWire =
    logic_core.WritableWire;

pub const Reg =
    logic_core.Reg;
pub const Internal =
    logic_core.Internal;
pub const Input =
    logic_core.Input;
pub const Output =
    logic_core.Output;
pub const Inout =
    logic_core.Inout;

pub const Time = core.Time;
pub const ClkTrigger = core.ClkTrigger;
pub const AssignType = enum(u1) { blocking, nonBlocking };
pub const AssignDetail = struct { t: AssignType = .blocking, d: Time = .pico(0) };
pub const SynthTarget = enum { verilog, vhdl, ngspice };
pub const Instruction = union(enum) {
    Assign: struct { toId: HDLId, fromId: HDLId, detail: AssignDetail },
    WaitOnDelay: Time,
    WaitOnClk: ClkTrigger,
    SubCircuit: HDLId,
};
pub fn CTX(comptime Module: type) type {
    return struct {
        module: Module,
        clk: u1,
        id: HDLId,
        instructions: std.MultiArrayList(Instruction),
        allocator: std.mem.Allocator,
        const Self = @This();
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .clk = 0,
                .id = .newId(.Ctx),
                .module = undefined,
                .instructions = .empty,
                .allocator = allocator,
            };
        }
        pub fn deinit(self: *Self) void {
            self.instructions.deinit(self.allocator);
        }
        pub fn registerElement(self: *Self, elem: anytype) void {
            _ = self;
            _ = elem;
            @compileError("TODO : not implemented");
        }
        pub fn assign(self: *Self, onto: anytype, value: anytype, detail: AssignDetail) void {
            logic_core.ensureWireAccess(@TypeOf(onto), .writableWire);
            logic_core.ensureWireAccess(@TypeOf(value), .wire);

            self.instructions.append(self.allocator, Instruction{ .Assign = .{
                .toId = onto.getId(),
                .fromId = value.getId(),
                .detail = detail,
            } }) catch unreachable; //TODO: wacky
            // @compileError("TODO : not implemented");
        }
        pub fn waitDelay(self: *Self, amt: Time) void {
            _ = self;
            _ = amt;
            @compileError("TODO : not implemented");
        }
        pub fn waitClk(self: *Self, trigger: ClkTrigger) void {
            _ = self;
            _ = trigger;
            @compileError("TODO : not implemented");
        }

        pub fn cases(self: *Self, value: anytype) []Self {
            _ = self;
            _ = value;
            @compileError("TODO : not implemented");
        }
        pub fn branch(self: *Self, cnd: anytype) []union(enum) { t: Self, f: Self } {
            _ = self;
            _ = cnd;
            @compileError("TODO : not implemented");
        }
        pub fn iter(self: *Self, comptime count: usize) []Self {
            _ = self;
            _ = count;
            @compileError("TODO : not implemented");
        }

        pub fn subCircuit(self: *Self) Self {
            _ = self;
            @compileError("TODO : not implemented");
        }
        pub fn subModule(self: *Self, comptime SubCtx: type) SubCtx {
            _ = self;
            @compileError("TODO : not implemented");
        }

        /// start
        pub fn start(self: *Self) void {
            _ = self;
            @compileError("TODO : not implemented");
        }
        /// compute wires
        pub fn step(self: *Self) void {
            _ = self;
            @compileError("TODO : not implemented");
        }
        /// step, then toggle clk
        pub fn stepClk(self: *Self) void {
            _ = self;
            @compileError("TODO : not implemented");
        }

        /// synthesis
        pub fn synth(self: *Self, target: SynthTarget) void {
            _ = self;
            _ = target;
            @compileError("TODO : not implemented");
        }
        // compute max delay
        pub fn dmax(self: *Self) Time {
            _ = self;
            @compileError("TODO : not implemented");
        }
    };
}

test "CTX magic" {
    const Ctx = CTX(struct {
        a: Reg(u32, .posedge),
        b: Reg(u16, .negedge),
    });
    var ctx = Ctx.init(testing.allocator);
    defer ctx.deinit();
    ctx.module.a = .init();
    ctx.module.b = .init();
    ctx.assign(ctx.module.a, ctx.module.b, .{});

    // ctx.branch(1, struct {
    //     fn True(_: anytype) void {}
    //     fn False(_: anytype) void {}
    // });

    // for (ctx.cases(1)) |x| switch (x) {
    //     0 => {...},
    //     1 => {...},
    //     ...
    // }
    // for (ctx.branch(1)) |x| switch (x) {
    //     .t => |ctx_i| {...},
    //     .f => |ctx_i| {...},
    // };
    // for (ctx.iter(32)) |ctx_i| {...}
    //

    // x.@"0"(12);
    // ctx.If(1, );
    // for (ctx.If(1)) |ctx_i| {
    //     _ = ctx_i;
    // }
    // for(ctx.branch(1), 0..) |
    // for(ctx.)
    // inline for (ctx.branch(1)) |ctx_c| switch (ctx_c) {
    //     .True => |ctx_t| {},
    //     .False => |ctx_f| {},
    // };
    // for(ctx.iter(32)) |ctx_i| {}
}
