// lib.cairo - Main module for pprf

pub mod pprf_contract;
pub mod pprf_interface;

// Re-export the interface for convenience
pub use pprf_interface::{IPprf, IPprfDispatcher, IPprfDispatcherTrait};
