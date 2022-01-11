use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn format(schema: String, params: String) -> String {
    prisma_fmt::format(&schema, &params)
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

/// The API is modelled on an LSP [completion
/// request](https://github.com/microsoft/language-server-protocol/blob/gh-pages/_specifications/specification-3-16.md#textDocument_completion).
/// Input and output are both JSON, the request being a `CompletionParams` object and the response
/// being a `CompletionList` object.
#[wasm_bindgen]
pub fn text_document_completion(schema: String, params: String) -> String {
    prisma_fmt::text_document_completion(&schema, &params)
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

#[wasm_bindgen]
pub fn enable_logs() {
    wasm_logger::init(wasm_logger::Config::default());
}
