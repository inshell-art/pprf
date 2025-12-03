// pprf_interface.cairo - Interface definition for PPRF

use core::array::Span;

#[starknet::interface]
pub trait IPprf<TState> {
    /// Core PPRF:
    ///   input:  arbitrary params chosen by caller
    ///   output: u32 in [0, 999_999], representing [0.0, 1.0)
    fn pprf(self: @TState, params: Span<felt252>) -> u32;
}
