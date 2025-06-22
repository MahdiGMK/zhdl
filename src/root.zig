const std = @import("std");
const testing = std.testing;
pub const core = @import("core.zig");
pub const logic_core = @import("logic_core.zig");
pub const module_core = @import("module_core.zig");
pub const std_modules = @import("std_modules.zig");
pub const HDLId = core.HDLId;
pub const traits = @import("traits.zig");
pub const Wire =
    traits.WireTrait;
pub const WritableWireTrait =
    traits.WritableWireTrait;

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
pub const ClkTrigger = core.EdgeTrigger;
pub const AssignType = module_core.AssignType;
pub const AssignDetail = module_core.AssignDetail;
pub const SynthTarget = module_core.SynthTarget;
pub const Instruction = module_core.Instruction;
pub const CTX = module_core.CTX;

test {
    _ = @import("core.zig");
    _ = @import("logic_core.zig");
    _ = @import("module_core.zig");
    _ = @import("std_modules.zig");
    _ = @import("traits.zig");
}
