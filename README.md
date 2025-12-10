# pprf

**pprf** is a tiny, fully on-chain pseudo‑random field glyph for Starknet.

It takes an arbitrary sequence of felts as input, hashes them with Poseidon,
then maps the result into a 6‑digit fixed‑point bucket:

- `render(params)` → `[v]`
- `v` is a `u32` in `[0, 999_999]`, encoded as `felt252`
- conceptually, `v / 1_000_000` is a random‑looking fraction in `[0, 1)`

`pprf` is designed to be used as a **GLYPH utility glyph**: lightweight,
stateless, composable, and suitable as a building block for FoC / SVG
generative art.

---

## Interface

`pprf` implements the GLYPH minimal protocol:

```cairo
#[starknet::interface]
pub trait IGlyph<TState> {
    /// Produce glyph data for given params.
    ///
    /// For pprf:
    /// - `params`: arbitrary caller-chosen felts (seed, salt, index, etc.)
    /// - return: `[v]`, where `v` is a u32 in [0, 999_999] encoded as felt252.
    fn render(self: @TState, params: Span<felt252>) -> Array<felt252>;

    /// Return static metadata about this glyph.
    ///
    /// This encodes a small key–value string, roughly:
    /// "name=pprf;kind=utility;scale=1000000;version=0.1.0"
    fn metadata(self: @TState) -> Span<felt252>;
}
```

### Behaviour

The core algorithm is:

1. Interpret the `params: Span<felt252>` as the input to Poseidon:
   ```cairo
   let h: felt252 = poseidon_hash_span(params);
   ```
2. Cast to `u256` and reduce modulo `1_000_000`:
   ```cairo
   let h_u256: u256 = h.into();
   let n: u256 = h_u256 % 1_000_000;
   ```
3. Convert to `u32`:
   ```cairo
   let v: u32 = n.try_into().unwrap(); // guaranteed 0 ≤ v ≤ 999_999
   ```
4. Return `[v.into()]` as `Array<felt252>`.

This gives you a deterministic, pseudo‑random integer `v` in `[0, 999_999]`
for any given `params`.

---

## How to use from another contract

A typical caller will treat `pprf` as an external glyph contract and use the
dispatcher generated for `IGlyph`.

Example pattern (simplified):

```cairo
use pprf::glyph_interface::IGlyphDispatcher;

#[storage_var]
fn pprf_glyph_address() -> ContractAddress;

fn sample(self: @ContractState, params: Span<felt252>) -> u32 {
    let addr = pprf_glyph_address::read();
    let glyph = IGlyphDispatcher { contract_address: addr };

    let out = glyph.render(params);
    // Expect exactly one element:
    assert(out.len() == 1, 'pprf: unexpected length');

    let v_felt = out.get_unchecked(0);
    let v_u32: u32 = v_felt.try_into().unwrap();

    v_u32 // 0 ..= 999_999
}
```

Typical downstream uses:

- **Fixed‑point fraction** in `[0, 1)`:
  - Conceptually treat `v / 1_000_000.0` as a 6‑digit fraction.
- **Indexing**:
  - `idx = v % N` to choose from a palette or layout group.
- **Seeding** further deterministic logic inside the caller.

---

## Immutability

`pprf` is intended to be **functionally immutable** once deployed:

- The behaviour “Poseidon → mod 1_000_000 → `[v]`” should not change at a
  given contract address.
- If the spec ever changes (e.g. different scale, different output shape),
  a new contract should be deployed and a new entry added to the GLYPH
  registry with an updated `version`.

No upgrade/proxy pattern is used; the contract is a plain Starknet contract
implementing `IGlyph`.

---

## Deployment

This repo is a Starknet / Scarb package.

### Requirements

- [Scarb](https://docs.swmansion.com/scarb/)
- Starknet toolchain (e.g. `starkli` or `snfoundry` / `sncast`)

### Build

```bash
scarb build
```

### Test

Using `cairo-test` via Scarb:

```bash
scarb test
```

### Deploy (example with starkli)

```bash
# 1. Declare the Sierra class
starkli declare target/dev/pprf_contract.sierra.json --network <your-network>

# 2. Deploy the contract
starkli deploy <class_hash> --network <your-network>
```

Record deployed addresses in `DEPLOYMENTS.md`. The GLYPH registry entry for
`Pprf` on Starknet Sepolia should point to the Sepolia deployment.

### Current deployment (Sepolia)

- **Class Hash**: `0x04db25300db2a6f90893136e20cda25274c87e8409efaf8ed650c2ac7c146097`
- **Contract Address**: `0x05968e1338e0791644f0fc8e561631a0092dc63f90a4c5b9af259c7bd225010f`
- **Declare Tx**: `0x00691acf2c780a4e3fd6e382103780d2fc5c2aa00e694b84aab127955ce8c142`
- **Deploy Tx**: `0x0733bb5b1d53590aa42ecdc9003db52cbd07b31d1c8e993f67cb7c83265c82ae`

RPC used: `https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_10/ixt6dg9JuoeZ8Tt6RGcA8`

---

## Metadata

`metadata()` returns a small ASCII/UTF‑8 string encoded as felts. The logical
content is split across two short strings to stay within the 31‑byte felt
limit:

```text
name=pprf;kind=utility;scale=
1000000;version=0.1.0
```

Tools that know how to decode this can:

- identify the glyph name and type (`utility`),
- understand the numeric scale (`1_000_000 → max value 999_999`),
- and track the behaviour version.

---

## Status

- **Kind**: utility glyph
- **Purpose**: reusable pseudo‑random bucket / fixed‑point source for FoC /
  generative art contracts.
- **Networks**: see `DEPLOYMENTS.md` for current deployments.
