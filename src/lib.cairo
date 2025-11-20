// pprf.cairo

use core::array::Span;

// 1.0 ↔ 1_000_000 (0..=999_999)
const NORMAL_SCALE: u256 = 1_000_000;

#[starknet::interface]
pub trait IPprf<TState> {
    /// Core PPRF:
    ///   input:  arbitrary params chosen by caller
    ///   output: u32 in [0, 999_999], representing [0.0, 1.0)
    fn pprf(self: @TState, params: Span<felt252>) -> u32;
}

#[starknet::contract]
mod Pprf {
    use core::poseidon::poseidon_hash_span;
    use super::NORMAL_SCALE;

    #[storage]
    struct Storage { // Empty: no mutable state, pure function.
    }

    #[abi(embed_v0)]
    impl PprfImpl of super::IPprf<ContractState> {
        fn pprf(self: @ContractState, params: Span<felt252>) -> u32 {
            // Poseidon(params) → felt252 → map to [0, 999_999]
            let h: u256 = poseidon_hash_span(params).into();
            let n: u256 = h % NORMAL_SCALE; // 0..=999_999
            n.try_into().unwrap()
        }
    }
}
