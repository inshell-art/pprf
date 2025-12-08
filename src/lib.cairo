// lib.cairo - Main module for pprf

pub mod glyph_interface;
pub mod pprf_contract;

// Re-export the interface for convenience
pub use glyph_interface::{IGlyph, IGlyphDispatcher, IGlyphDispatcherTrait};
