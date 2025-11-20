use core::array::{Array, ArrayTrait};
use pprf::{IPprfDispatcher, IPprfDispatcherTrait, IPprfSafeDispatcher, IPprfSafeDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_pprf_is_deterministic() {
    let mut inputs: Array<felt252> = ArrayTrait::new();
    inputs.append(10);
    inputs.append(77);

    let contract_address = deploy_contract("Pprf");
    let dispatcher = IPprfDispatcher { contract_address };

    let result1 = dispatcher.pprf(inputs.span());
    let result2 = dispatcher.pprf(inputs.span());

    assert(result1 == result2, 'PRF should be deterministic');
    assert(result1 < 1_000_000, 'Result should be < 1_000_000');
}

#[test]
fn test_pprf_different_inputs() {
    let mut inputs_first: Array<felt252> = ArrayTrait::new();
    inputs_first.append(3);
    inputs_first.append(99);

    let mut inputs_second: Array<felt252> = ArrayTrait::new();
    inputs_second.append(4);
    inputs_second.append(99);

    let contract_address = deploy_contract("Pprf");
    let dispatcher = IPprfDispatcher { contract_address };

    let first_value = dispatcher.pprf(inputs_first.span());
    let second_value = dispatcher.pprf(inputs_second.span());

    assert(first_value != second_value, 'Different inputs differ');
    assert(first_value < 1_000_000, 'Result1 < 1M');
    assert(second_value < 1_000_000, 'Result2 < 1M');
}

#[test]
#[feature("safe_dispatcher")]
fn test_pprf_variable_length() {
    let contract_address = deploy_contract("Pprf");
    let safe_dispatcher = IPprfSafeDispatcher { contract_address };

    let mut short_inputs: Array<felt252> = ArrayTrait::new();
    short_inputs.append(5);

    let mut long_inputs: Array<felt252> = ArrayTrait::new();
    long_inputs.append(5);
    long_inputs.append(6);
    long_inputs.append(7);

    let short_result = safe_dispatcher.pprf(short_inputs.span()).unwrap();
    let long_result = safe_dispatcher.pprf(long_inputs.span()).unwrap();

    assert(short_result != long_result, 'Different inputs differ');
    assert(short_result < 1_000_000, 'Short < 1M');
    assert(long_result < 1_000_000, 'Long < 1M');
}
