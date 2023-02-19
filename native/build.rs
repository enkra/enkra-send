use lib_flutter_rust_bridge_codegen::{
    config_parse, frb_codegen, get_symbols_if_no_duplicates, RawOpts,
};

fn main() {
    let config = RawOpts {
        rust_input: vec!["src/api.rs".to_string()],
        dart_output: vec!["../lib/native/bridge_generated.dart".to_string()],
        inline_rust: true,
        wasm: true,
        skip_add_mod_to_lib: true,
        ..Default::default()
    };

    let mut config = config_parse(config);

    let symbols = get_symbols_if_no_duplicates(&config).unwrap();

    for c in &mut config {
        frb_codegen(&c, &symbols).unwrap();
    }
}
