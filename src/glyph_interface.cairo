// glyph_interface.cairo - GLYPH-compatible interface

use core::array::{Array, Span};

/// Minimal GLYPH protocol for utility / SVG glyphs.
#[starknet::interface]
pub trait IGlyph<TState> {
    /// Produce glyph data for the given params.
    ///
    /// For pprf:
    /// - params: arbitrary caller-chosen felts (seed, index, salt, etc.)
    /// - return: Array of felts; element[0] is a u32 in [0, 999_999] encoded
    ///   as felt252.
    fn render(self: @TState, params: Span<felt252>) -> Array<felt252>;

    /// Return static metadata about this glyph (optional; can be empty).
    ///
    /// This can encode name, kind, version, param schema, etc. as UTF-8 bytes
    /// packed into felts if desired.
    fn metadata(self: @TState) -> Span<felt252>;
}
