// pprf_contract.cairo - Pure Pseudorandom Function contract implementation

use core::array::{Array, ArrayTrait, Span};
use core::poseidon::poseidon_hash_span;

// 1.0 ↔ 1_000_000 (0..=999_999)
const NORMAL_SCALE: u256 = 1_000_000;

fn pprf_value(params: Span<felt252>) -> u32 {
    // Poseidon(params) → felt252 → map to [0, 999_999]
    let h: u256 = poseidon_hash_span(params).into();
    let n: u256 = h % NORMAL_SCALE; // 0..=999_999
    n.try_into().unwrap()
}

fn render_glyph(params: Span<felt252>) -> Array<felt252> {
    let pprf = pprf_value(params);

    let mut data = ArrayTrait::new();
    data.append(pprf.into());
    data
}

fn metadata_glyph() -> Span<felt252> {
    let mut data = ArrayTrait::new();
    // Registry stanza split into two short-string felts to stay under 31 bytes each.
    data.append('name=pprf;kind=utility;scale=');
    data.append('1000000;version=0.1.0');
    data.span()
}

#[starknet::contract]
pub mod Pprf {
    use core::array::{Array, Span};
    use super::{metadata_glyph, render_glyph};

    #[storage]
    struct Storage { // Empty: no mutable state, pure function.
    }

    #[abi(embed_v0)]
    impl GlyphImpl of super::super::glyph_interface::IGlyph<ContractState> {
        fn render(self: @ContractState, params: Span<felt252>) -> Array<felt252> {
            render_glyph(params)
        }

        fn metadata(self: @ContractState) -> Span<felt252> {
            metadata_glyph()
        }
    }
}

#[cfg(test)]
mod tests {
    use core::array::{Array, ArrayTrait, SpanTrait};
    use core::traits::TryInto;
    use super::*;

    #[test]
    fn render_maps_poseidon_to_scaled_value() {
        let mut params = ArrayTrait::new();
        params.append(1);
        params.append(2);
        params.append(3);

        let expected_hash: u256 = poseidon_hash_span(params.span()).into();
        let expected: u32 = (expected_hash % NORMAL_SCALE).try_into().unwrap();

        let result = render_glyph(params.span());

        assert(result.len() == 1, 'len');
        let rendered: u32 = (*result.at(0_usize)).try_into().unwrap();
        assert(rendered == expected, 'render output mismatch');
    }

    #[test]
    fn metadata_matches_registry_stanza() {
        let meta = metadata_glyph();

        assert(meta.len() == 2, 'metadata len mismatch');
        assert(*meta.at(0_usize) == 'name=pprf;kind=utility;scale=', 'metadata part0 mismatch');
        assert(*meta.at(1_usize) == '1000000;version=0.1.0', 'metadata part1 mismatch');
    }

    #[test]
    fn render_is_deterministic() {
        let mut params = ArrayTrait::new();
        params.append(42);
        params.append(7);
        params.append(99);

        let first = render_glyph(params.span());
        let second = render_glyph(params.span());

        assert(first.len() == 1, 'len');
        assert(second.len() == 1, 'len');
        assert(*first.at(0_usize) == *second.at(0_usize), 'nondeterministic');
    }

    #[test]
    fn render_accepts_empty_params() {
        let params: Array<felt252> = array![];
        let result = render_glyph(params.span());

        assert(result.len() == 1, 'len');
        let value: u32 = (*result.at(0_usize)).try_into().unwrap();
        assert(value <= 999_999_u32, 'out of range');
    }
}
