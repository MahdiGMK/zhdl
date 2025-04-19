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
    Assign: struct { toId: HDLId(.Wire), fromId: HDLId(.Wire), detail: AssignDetail },
    WaitOnDelay: Time,
    WaitOnClk: ClkTrigger,
    Cases: struct { condId: HDLId(.Wire), cases: []HDLId(.Circuit) },
    Iter: struct { iterations: []HDLId(.Circuit) },
    SubCircuit: HDLId(.Circuit),
};
pub const CircuitPool = struct {
    var allocator: std.mem.Allocator = undefined;
    var circuits: std.AutoHashMapUnmanaged(HDLId(.Circuit), Circuit) = .empty;
    pub fn initPool(alloc: std.mem.Allocator) void {
        std.debug.print("pool init\n", .{});
        allocator = alloc;
        circuits = .empty;
    }
    pub fn deinitPool() void {
        std.debug.print("pool deinit\n", .{});
        var iter = circuits.valueIterator();
        while (iter.next()) |circ| {
            circ.deinit();
        }
        circuits.deinit(allocator);
    }
    pub fn storeCirc(circ: *Circuit) !void {
        try circuits.put(allocator, circ.id, circ.*);
    }
};
pub const Circuit = struct {
    id: HDLId(.Circuit),
    meta: usize,
    instructions: std.ArrayListUnmanaged(Instruction),
    const This = @This();
    pub fn getInstructions(self: This) []Instruction {
        return self.instructions.toOwnedSlice();
    }
    pub fn init(meta: usize) This {
        const self = This{
            .id = .newId(),
            .meta = meta,
            .instructions = .empty,
        };
        std.debug.print("init : {}\n", .{self.id});
        return self;
    }
    pub fn store(self: *This) !void {
        std.debug.print("store in pool : {}\n", .{self.id});
        try CircuitPool.storeCirc(self);
    }
    pub fn deinit(self: *This) void { // copy circ to circpool1
        std.debug.print("deinit : {}\n", .{self.id});
        self.instructions.deinit(CircuitPool.allocator);
    }
    pub fn registerElement(self: *This, elem: anytype) void {
        _ = self;
        _ = elem;
        @compileError("TODO : not implemented");
    }
    pub fn assign(self: *This, onto: anytype, value: anytype, detail: AssignDetail) !void {
        logic_core.ensureWireAccess(@TypeOf(onto), .writableWire);
        logic_core.ensureWireAccess(@TypeOf(value), .wire);
        logic_core.ensureSameType(@TypeOf(onto), @TypeOf(value));

        try self.instructions.append(CircuitPool.allocator, Instruction{ .Assign = .{
            .toId = onto.getId(),
            .fromId = value.getId(),
            .detail = detail,
        } });
    }
    pub fn waitDelay(self: *This, amt: Time) !void {
        try self.instructions.append(CircuitPool.allocator, Instruction{ .WaitOnDelay = amt });
    }
    pub fn waitClk(self: *This, trigger: ClkTrigger) void {
        try self.instructions.append(CircuitPool.allocator, Instruction{ .WaitOnClk = trigger });
    }

    pub fn cases(self: *This, value: anytype) []struct { meta: @TypeOf(value).Type, ctx: This } {
        logic_core.ensureWireAccess(@TypeOf(value), .wire);
        _ = self;
        @compileError("TODO : not implemented");
    }
    pub fn branch(self: *This, cnd: anytype) []This {
        logic_core.ensureWireAccess(@TypeOf(cnd), .wire);
        const case = [_]This{ .init(0), .init(1) };
        self.instructions.append(CircuitPool.allocator, Instruction{
            .Cases = .{
                .conditionId = cnd.getId(),
                .cases = .{ case[0].id, case[1].id },
            },
        });
        return case;
    }
    pub fn iter(self: *This, comptime count: usize) []This {
        const iters: [count]This = undefined;
        for (iters, 0..) |*it, meta| {
            it.* = .init(meta);
        }
        self.instructions.append(
            CircuitPool.allocator,
        );
    }

    pub fn subCircuit(self: *This) This {
        _ = self;
        @compileError("TODO : not implemented");
        // self.instructions.append(gpa: Allocator, elem: T)
    }
    pub fn subModule(self: *This, comptime SubCtx: type) SubCtx {
        _ = self;
        @compileError("TODO : not implemented");
    }

    /// start
    pub fn start(self: *This) void {
        _ = self;
        @compileError("TODO : not implemented");
    }
    /// compute wires
    pub fn step(self: *This) void {
        _ = self;
        @compileError("TODO : not implemented");
    }
    /// step, then toggle clk
    pub fn stepClk(self: *This) void {
        _ = self;
        @compileError("TODO : not implemented");
    }

    /// synthesis
    pub fn synth(self: *This, target: SynthTarget) void {
        _ = self;
        _ = target;
        @compileError("TODO : not implemented");
    }
    // compute max delay
    pub fn dmax(self: *This) Time {
        _ = self;
        @compileError("TODO : not implemented");
    }
};

test "CTX magic" {
    // var a = Reg(u8, .posedge).init();
    // const b = Reg(u8, .posedge).init();
    CircuitPool.initPool(testing.allocator);
    defer CircuitPool.deinitPool();

    {
        var ctx = Circuit.init(0);
        defer ctx.store() catch {};
        // try ctx.assign(a.asWritableWire(), b, .{}); // a = b;
    }

    // ctx.branch(1, struct {
    //     fn True(_: anytype) void {}
    //     fn False(_: anytype) void {}
    // });

    // for (ctx.cases(1)) |ctx_i| switch (ctx_i.meta) {
    //     0 => {...},
    //     1 => {...},
    //     ...
    // }
    // for (ctx.branch(1)) |ctx_i|
    //     if (ctx_i.meta) {...}
    //     else {...}
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
