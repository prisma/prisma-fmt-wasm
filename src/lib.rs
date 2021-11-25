use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn format(input: String) -> String {
    prisma_fmt::format(input)
}

#[wasm_bindgen]
pub fn lint(input: String) -> String {
    prisma_fmt::lint(input)
}

#[wasm_bindgen]
pub fn native_types(input: String) -> String {
    prisma_fmt::native_types(input)
}

#[wasm_bindgen]
pub fn referential_actions(input: String) -> String {
    prisma_fmt::referential_actions(input)
}

#[wasm_bindgen]
pub fn preview_features() -> String {
    prisma_fmt::preview_features()
}

#[wasm_bindgen]
pub fn version() -> String {
    String::from("wasm")
}

/// Trigger a panic inside the wasm module. This is only useful in development for testing panic
/// handling.
#[wasm_bindgen]
pub fn debug_panic() {
    panic!("This is the panic triggered by `prisma_fmt::debug_panic()`");
}
