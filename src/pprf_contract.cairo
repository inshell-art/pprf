// pprf_contract.cairo - Pure Pseudorandom Function contract implementation

use core::poseidon::poseidon_hash_span;

// 1.0 ↔ 1_000_000 (0..=999_999)
const NORMAL_SCALE: u256 = 1_000_000;

#[starknet::contract]
pub mod Pprf {
    use super::{NORMAL_SCALE, poseidon_hash_span};

    #[storage]
    struct Storage { // Empty: no mutable state, pure function.
    }

    #[abi(embed_v0)]
    impl PprfImpl of super::super::pprf_interface::IPprf<ContractState> {
        fn pprf(self: @ContractState, params: Span<felt252>) -> u32 {
            // Poseidon(params) → felt252 → map to [0, 999_999]
            let h: u256 = poseidon_hash_span(params).into();
            let n: u256 = h % NORMAL_SCALE; // 0..=999_999
            n.try_into().unwrap()
        }
    }
}
