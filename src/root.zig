const std = @import("std");
const testing = std.testing;

pub const Delay = struct {
    val_in_ps: usize,
    pub fn micro(val: usize) Delay {
        return .{ .val_in_ps = val * 1000_000 };
    }
    pub fn nano(val: usize) Delay {
        return Delay{ .val_in_ps = val * 1000 };
    }
    pub fn pico(val: usize) Delay {
        return .{ .val_in_ps = val };
    }
    pub fn toPico(self: *Delay) usize {
        return self.val_in_ps;
    }
    pub fn toNano(self: *Delay) usize {
        return (self.val_in_ps + 999) / 1000;
    }
    pub fn toMicro(self: *Delay) usize {
        return (self.val_in_ps + 999_999) / 1000_000;
    }
};
pub const ClkTrigger = enum(u2) { none = 0, posedge = 1, negedge = 2, both = 3 };
pub const AssignType = enum(u1) { blocking, nonBlocking };
pub const AssignDetail = struct { t: AssignType = .blocking, d: Delay = .fromPico(0) };
pub const SynthTarget = enum { verilog, vhdl, ngspice };
pub fn CTX(comptime Module: type) type {
    return struct {
        module: Module,
        pub fn init() @This() {
            @compileError("TODO : not implemented");
        }
        pub fn assign(self: *@This(), onto: *WritableWire, value: *Wire, detail: AssignDetail) void {
            _ = self;
            _ = onto;
            _ = value;
            _ = detail;
            @compileError("TODO : not implemented");
        }
        pub fn delay(self: *@This(), amt: Delay) void {
            _ = self;
            _ = amt;
            @compileError("TODO : not implemented");
        }
        pub fn clk(self: *@This(), trigger: ClkTrigger) void {
            _ = self;
            _ = trigger;
            @compileError("TODO : not implemented");
        }

        pub fn iter(self: *@This(), comptime count: usize) []@This() {
            _ = self;
            _ = count;
            @compileError("TODO : not implemented");
        }
        pub fn subcircuit(self: *@This()) @This() {
            _ = self;
            @compileError("TODO : not implemented");
        }
        pub fn submodule(self: *@This(), comptime SubCtx: type) SubCtx {
            _ = self;
            @compileError("TODO : not implemented");
        }

        /// start
        pub fn start(self: *@This()) void {
            _ = self;
            @compileError("TODO : not implemented");
        }
        /// compute wires
        pub fn step(self: *@This()) void {
            _ = self;
            @compileError("TODO : not implemented");
        }
        /// step, then toggle clk
        pub fn stepClk(self: *@This()) void {
            _ = self;
            @compileError("TODO : not implemented");
        }

        /// synthesis
        pub fn synth(self: *@This(), target: SynthTarget) void {
            _ = self;
            _ = target;
            @compileError("TODO : not implemented");
        }
        // compute max delay
        pub fn dmax(self: *@This()) Delay {
            _ = self;
            @compileError("TODO : not implemented");
        }
    };
}

fn Wire(comptime UnderlayingType: type) type {
    return struct { read: fn () UnderlayingType };
}
fn WritableWire(comptime UnderlayingType: type) type {
    return struct { write: fn (*UnderlayingType) void, read: fn () UnderlayingType };
}

pub fn Reg(comptime UnderlayingType: type) type {
    _ = UnderlayingType;
    @compileError("TODO : not implemented");
}
pub fn Input(comptime UnderlayingType: type) type {
    _ = UnderlayingType;
    @compileError("TODO : not implemented");
}
pub fn Output(comptime UnderlayingType: type) type {
    _ = UnderlayingType;
    @compileError("TODO : not implemented");
}
pub fn Inout(comptime UnderlayingType: type) type {
    _ = UnderlayingType;
    @compileError("TODO : not implemented");
}

test "CTX magic" {
    const Ctx = CTX(struct {
        a: u32,
        b: u16,
    });
    var ctx = Ctx.init();
    ctx.module.a += 1;
}
