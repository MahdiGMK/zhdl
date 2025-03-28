# GOALS

1. simulation should be as fast as possible (using accelerated cpu and/or gpu instruction)
2. you should be able to easily express your zig code, with a minimal change you will be able to convert it to synthesizable zhdl code.
3. all types would match their circuit counter part, so ptr-deref is prohibited
4. provide robust, testable, understandable and fast circuits

# NON-GOALS

1. general-purpose HLS

# API Patterns

```zig
simple_module_file: {
    
    const Input = HDLINPUT( struct { a: In(u32), ... } ); // is In(...) realy needed?
    const Output = HDLOUTPUT( struct { out: Out(u32), ... } ); // is Out(...) realy needed?
    const Context = HDLCTX( struct { reg: Reg(u64, .posedge), ... } );
    
    comptime fn simpleModule(ctx: *Context, inp: *Input, out: *Output) void {
        // assumption : we need out-pins at the same time
        // assignments?
        ctx.assign(out.out, inp.a, .{});                      // out = a;
        ctx.assign(out.out, inp.a, .{t: .blocking, d: 1});       // out = #1 a;
        ctx.assign(out.out, inp.a, .{t: .nonBlocking, d: 2});    // out <= #2 a;

        ctx.delay(3); //  #3;
        ctx.clk(.posedge); // @(posedge clk);

        // idk - good to have! - clk/delay/cost optimization
        for (ctx.iter(32)) |ctx_i| { ... }
    }

    comptime fn submoduleSample(ctx: *Context, inp: *Input, out: *Output) void {
        // sub-circuit doesn't own its context
        subcircuitA(ctx.subcircuit(), inp, out);
        subcircuitB(ctx.subcircuit(), inp, out);
        // sub-module owns its context
        submoduleA(ctx.submodule(AContext), inp, out); 
        submoduleB(ctx.submodule(BContext), inp, out); 
    }

    comptime fn subcircuitA(ctx: *Context, inp: *Input, out: *Output) void { ... }
    comptime fn subcircuitB(ctx: *Context, inp: *Input, out: *Output) void { ... }
    const AContext = HDLCTX( struct { ... } );
    const BContext = HDLCTX( struct { ... } );
    comptime fn submoduleA(ctx: *AContext, inp: *Input, out: *Output) void { ... }
    comptime fn submoduleB(ctx: *BContext, inp: *Input, out: *Output) void { ... }


    // module simulation
    fn simpleModule_sim() void {
        var ctx = Context.init();
        var inp = Input.init();
        var out = Output.init();
        
        // module instantiation
        simpleModule(ctx, inp, out);
        
        // module simulation
        ctx.start();
        inp.a.write(12);
        ctx.step(); // step_clk() -> step, then toggle clk
        std.debug.print("out : {}", .{out.out.read()});
    }

    // module synthesis
    fn simpleModule_synth() void {
        var ctx = Context.init();
        var inp = Input.init();
        var out = Output.init();
        
        // module instantiation
        simpleModule(ctx, inp, out);

        // module synthesis
        ctx.synth(.verilog); // vhdl | ngspice | ...?
        
    }
}
```
