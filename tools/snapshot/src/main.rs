// Runs a Luau script with two helpers (readfile, compile) so the game's real model code
// can execute outside Roblox against mocked Roblox types. Usage: freek-snapshot harness.luau [args...]
use mlua::{Error, Lua, Result};

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let harness = args.first().cloned().expect("usage: freek-snapshot harness.luau [args...]");

    let lua = Lua::new();
    let globals = lua.globals();
    globals.set(
        "readfile",
        lua.create_function(|_, path: String| std::fs::read_to_string(&path).map_err(Error::external))?,
    )?;
    globals.set(
        "compile",
        lua.create_function(|lua, (source, name): (String, String)| lua.load(source).set_name(name).into_function())?,
    )?;
    globals.set("ARGS", args.clone())?;

    let source = std::fs::read_to_string(&harness).map_err(Error::external)?;
    lua.load(source).set_name(harness).exec()
}
