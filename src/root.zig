const std = @import("std");
const testing = std.testing;

pub const HDLId = struct {
    value: usize = 0,
    const Self = @This();
    pub fn valid(self: *Self) bool {
        return self.value != 0;
    }
    pub fn newId() Self {
        const State = struct {
            var global_id_counter: usize = 0;
        };
        State.global_id_counter += 1;
        return Self{ .value = State.global_id_counter };
    }
};
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
pub const ClkTrigger = enum(u2) { none = 0, posedge = 1, negedge = 2, both = 3 };
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

fn Wire(
    comptime Context: type,
    comptime UnderlayingType: type,
    comptime readfn: fn (ctx: Context) ?UnderlayingType,
) type {
    return struct {
        context: Context,
        pub inline fn read(self: *@This()) ?UnderlayingType {
            return readfn(self.context);
        }
    };
}
fn WritableWire(
    comptime Context: type,
    comptime UnderlayingType: type,
    readfn: fn (ctx: Context) ?UnderlayingType,
    writefn: fn (ctx: Context, value: ?UnderlayingType) void,
) type {
    return struct {
        context: Context,
        const WireT = Wire(Context, UnderlayingType, readfn);
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
        pub inline fn read(self: *Self) ?UnderlayingType {
            return self.value;
        }
        pub inline fn write(self: *Self, value: ?UnderlayingType) void {
            self.shadow = value;
        }
        const WireT = Wire(Self, UnderlayingType, read);
        const WritableWireT = WritableWire(Self, UnderlayingType, read, write);
        pub inline fn asWire(self: *Self) WireT {
            return WireT{ .context = self };
        }
        pub inline fn asWritableWire(self: *Self) WireT {
            return WritableWireT{ .context = self };
        }
    };
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
        a: Reg(u32, .posedge),
        b: Reg(u16, .negedge),
    });
    var ctx = Ctx.init();
    ctx.module.a = .init();
    ctx.module.b = .init();
}
