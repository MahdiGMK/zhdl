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

pub const Time = struct {
    val_in_ps: usize,
    pub fn micro(val: usize) Time {
        return .{ .val_in_ps = val * 1000_000 };
    }
    pub fn nano(val: usize) Time {
        return Time{ .val_in_ps = val * 1000 };
    }
    pub fn pico(val: usize) Time {
        return .{ .val_in_ps = val };
    }
    pub fn toPico(self: *Time) usize {
        return self.val_in_ps;
    }
    pub fn toNano(self: *Time) usize {
        return (self.val_in_ps + 999) / 1000;
    }
    pub fn toMicro(self: *Time) usize {
        return (self.val_in_ps + 999_999) / 1000_000;
    }
};
pub const ClkTrigger = core.ClkTrigger;
pub const AssignType = enum(u1) { blocking, nonBlocking };
pub const AssignDetail = struct { t: AssignType = .blocking, d: Time = .pico(0) };
pub const SynthTarget = enum { verilog, vhdl, ngspice };
const Instructions = union(enum) {};
pub fn CTX(comptime Module: type) type {
    return struct {
        module: Module,
        clk: u1,
        id: HDLId,
        const Self = @This();
        pub fn init() Self {
            var self: Self = undefined;
            self.clk = 0;
            self.id = .newId();

            // @compileError("TODO : not implemented");
            return self;
        }
        pub fn assign(self: *Self, onto: *WritableWire, value: *Wire, detail: AssignDetail) void {
            _ = self;
            _ = onto;
            _ = value;
            _ = detail;
            @compileError("TODO : not implemented");
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

        pub fn iter(self: *Self, comptime count: usize) []Self {
            _ = self;
            _ = count;
            @compileError("TODO : not implemented");
        }
        pub fn subcircuit(self: *Self) Self {
            _ = self;
            @compileError("TODO : not implemented");
        }
        pub fn submodule(self: *Self, comptime SubCtx: type) SubCtx {
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
    var ctx = Ctx.init();
    ctx.module.a = .init();
    ctx.module.b = .init();
}
