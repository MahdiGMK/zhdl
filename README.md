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
    const Context = HDLCTX( struct { reg: Reg(u64), ... } );
    
    fn simpleModule(ctx: *Context, inp: Input, out: *Output) void {
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

    fn multiplexing(ctx: *Context, inp: Input, out: *Output) void {
        ctx.submodule(multiplexingA, ctx, inp, out);
        ctx.submodule(multiplexingB, ctx, inp, out);
    }

    fn multiplexingA(ctx: *Context, inp: Input, out: *Output) void { ... }
    fn multiplexingB(ctx: *Context, inp: Input, out: *Output) void { ... }
}
```
