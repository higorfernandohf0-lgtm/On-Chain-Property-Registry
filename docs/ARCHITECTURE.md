# Architecture

## Overview

On-Chain Property Registry is a Solidity smart contract designed to record property metadata references, valuations, and ownership state on-chain.

The architecture intentionally separates blockchain state from real-world property documents.

The smart contract stores only the information required for the registry logic, while descriptive metadata and documents are expected to remain off-chain and be referenced through an IPFS-compatible URI.

This design reduces on-chain storage costs while preserving a verifiable link between a property record and its metadata.

---

## Architecture Goals

The contract was designed around the following principles:

- Minimal and understandable smart contract logic
- Explicit ownership rules
- Controlled emergency pause mechanism
- Gas-conscious storage layout
- Clear revert behavior through custom errors
- Off-chain metadata separation
- Strong automated testing
- Reduced attack surface
- Explicit trust assumptions

The goal is not to reproduce a government land registry or establish legal ownership of physical real estate.

Instead, the project demonstrates a security-focused architecture for maintaining property registry state on an EVM-compatible blockchain.

---

## Core Components

The system currently consists of four primary components:

```text
User
  |
  v
PropertyRegistry.sol
  |
  +-- Property Storage
  |
  +-- Ownership Logic
  |
  +-- Administrative Controls
  |
  +-- Events
  |
  v
IPFS-Compatible Metadata
```

### PropertyRegistry

`PropertyRegistry.sol` is the core contract.

It is responsible for:

- Registering properties
- Assigning sequential property IDs
- Recording property owners
- Recording property valuations
- Recording registration timestamps
- Referencing off-chain metadata
- Transferring property ownership
- Pausing sensitive state-changing operations

---

## Property Data Model

Each property is represented by the following structure:

```solidity
struct Property {
    uint256 price;
    address owner;
    uint40 registeredAt;
    string propertyURI;
}
```

### `price`

Stores the property's valuation in the application's chosen base unit.

This field does not represent an ETH payment and the contract does not transfer funds during registration or ownership transfer.

### `owner`

Stores the address currently associated with ownership of the registry entry.

The property owner is independent from the administrative owner of the contract.

### `registeredAt`

Stores the block timestamp at which the property was registered.

A `uint40` is sufficient for practical Unix timestamp storage while allowing it to share a storage slot with the `address owner` field.

### `propertyURI`

References off-chain property metadata.

The intended format is an IPFS-compatible URI such as:

```text
ipfs://<content-identifier>
```

The contract currently validates only that the URI is non-empty. It does not enforce a specific URI scheme.

---

## Storage Architecture

Properties are stored using:

```solidity
mapping(uint256 propertyId => Property property) private _properties;
```

Property IDs are sequential and generated through:

```solidity
uint256 private _nextPropertyId;
```

A newly registered property receives the current `_nextPropertyId`, after which the counter is incremented.

Properties are currently never deleted.

Because IDs are sequential and deletion is not supported, the contract can determine whether a property exists by verifying:

```text
propertyId < _nextPropertyId
```

This assumption is part of the current architecture and must be reconsidered if property deletion is introduced in the future.

---

## Storage Packing

The structure intentionally places:

```solidity
address owner;
uint40 registeredAt;
```

next to each other.

An Ethereum storage slot contains 32 bytes.

An address requires 20 bytes and `uint40` requires 5 bytes, allowing both values to fit within the same storage slot.

This reduces unnecessary storage usage compared with using a full `uint256` for the timestamp.

The dynamic `string propertyURI` requires separate storage because its size is not fixed.

---

## Administrative Ownership

Administrative access is implemented using OpenZeppelin's `Ownable2Step`.

Administrative ownership and property ownership are intentionally separate concepts.

The administrative owner can:

- Pause the registry
- Unpause the registry
- Initiate transfer of administrative ownership

The administrative owner cannot use these privileges to arbitrarily transfer a registered property belonging to another address.

This reduces the authority of the administrator over individual property records.

---

## Two-Step Administrative Transfer

`Ownable2Step` is used instead of a single-step ownership transfer.

Administrative ownership transfer follows this model:

```text
Current Admin
     |
     | transferOwnership(newAdmin)
     v
Pending Admin
     |
     | acceptOwnership()
     v
New Admin
```

This reduces the risk of permanently transferring administrative control to an incorrect address.

---

## Emergency Pause Mechanism

The contract inherits OpenZeppelin's `Pausable`.

When paused, the following operations are blocked:

- Property registration
- Property ownership transfers

Read operations remain available.

This provides an emergency mechanism for stopping state changes if unexpected behavior or a security issue is discovered.

Only the administrative owner can pause or unpause the contract.

---

## Property Registration Flow

The registration flow is:

```text
User
 |
 | registerProperty(propertyURI, price)
 v
Validate URI
 |
 v
Validate Price
 |
 v
Generate Property ID
 |
 v
Store Property
 |
 v
Increment Counter
 |
 v
Emit PropertyRegistered
```

Registration requires:

- A non-empty metadata URI
- A price greater than zero

The caller automatically becomes the owner of the newly registered property.

---

## Property Ownership Transfer Flow

Property ownership transfers follow:

```text
Current Property Owner
        |
        | transferPropertyOwnership(propertyId, newOwner)
        v
Validate newOwner
        |
        v
Validate property existence
        |
        v
Validate caller ownership
        |
        v
Reject same-owner transfer
        |
        v
Update owner
        |
        v
Emit PropertyOwnershipTransferred
```

Only the current property owner can transfer the property record.

The new owner cannot be the zero address or the current owner.

---

## Custom Errors

The contract uses custom errors instead of revert strings for contract-specific validation.

Examples include:

```solidity
error PropertyNotFound(uint256 propertyId);
error ZeroAddress();
error EmptyPropertyURI();
error InvalidPrice(uint256 price);
error SameOwner(address owner);
```

Custom errors provide structured failure information while generally requiring less bytecode and gas than long revert strings.

---

## Reentrancy Design

The contract intentionally does not currently use `ReentrancyGuard`.

The state-changing property functions do not:

- Transfer ETH
- Transfer tokens
- Call external contracts
- Execute user-provided callbacks

As a result, the current call graph does not expose a reentrancy entry point through these operations.

An earlier version included `ReentrancyGuard` as defense-in-depth. It was removed after reviewing the contract's external interaction surface.

This reduced bytecode size and gas consumption without removing a protection required by the current architecture.

If future versions introduce external calls, token transfers, payment logic, hooks, or callbacks, reentrancy risk must be reassessed before deployment.

---

## Deployment Provenance

The contract stores the deployment chain ID using:

```solidity
uint256 public immutable DEPLOYMENT_CHAIN_ID;
```

The value is assigned from:

```solidity
block.chainid
```

during construction.

Because it is immutable, it does not require a regular mutable storage slot after deployment.

This value provides simple deployment provenance and allows clients to identify the chain for which the registry instance was created.

---

## Off-Chain Metadata

Detailed property information should remain outside the smart contract.

An example architecture is:

```text
PropertyRegistry
      |
      | propertyURI
      v
IPFS Metadata
      |
      +-- Property description
      +-- Property type
      +-- General location information
      +-- Document references
      +-- Additional metadata
```

Sensitive personal information should not be stored directly on-chain.

Real-world documents should also be evaluated carefully before being published to permanent public storage such as IPFS.

---

## Trust Model

The current registry uses a self-registration model.

Any blockchain address may register a property record.

The smart contract does not independently verify that:

- The caller legally owns a physical property
- The metadata represents a real property
- The supplied valuation is accurate
- The documents are authentic
- A government registry recognizes the record

Therefore, ownership inside this contract represents ownership of the on-chain registry entry, not automatically legal ownership of physical real estate.

A production real-world implementation would require additional mechanisms such as:

- Authorized property verifiers
- Government or institutional integrations
- Trusted oracle systems
- Identity verification
- Legal and jurisdiction-specific processes

These mechanisms are intentionally outside the scope of the current portfolio implementation.

---

## Security Boundaries

The architecture separates three concepts:

```text
Administrative Ownership
        |
        | controls pause state
        v
PropertyRegistry
        ^
        |
Property Ownership
        |
        | controls individual property transfers
        |
      Users
```

The administrative owner manages contract-level emergency controls.

Property owners manage their individual registry entries.

Off-chain systems remain responsible for validating the relationship between blockchain records and real-world assets.

---

## Testing Architecture

The project uses Foundry for automated testing.

The test strategy currently includes:

- Unit tests
- Revert tests
- Event tests
- Access-control tests
- Fuzz testing
- Stateful invariant testing

The core `PropertyRegistry.sol` contract currently reaches full line, statement, branch, and function coverage under the project's Foundry coverage suite.

Coverage is treated as a measurement of executed code paths, not proof that the contract is free from vulnerabilities.

---

## Invariants

The stateful invariant suite continuously exercises property registration and ownership transfers.

The current invariants verify that:

- Registered property owners are never the zero address
- Registered property prices are never zero
- Registered property URIs are never empty
- Registered properties remain readable

These properties describe conditions expected to remain true regardless of valid sequences of operations generated by the invariant handler.

---

## Current Limitations

The current version intentionally does not implement:

- Legal verification of physical property ownership
- Property deletion
- Property metadata updates
- ETH payments
- Token payments
- Escrow
- NFT representation
- Oracle integrations
- Identity verification
- Government registry integration
- Upgradeable proxy architecture

Keeping these features outside the current implementation reduces complexity and attack surface while allowing the project to focus on smart contract architecture, testing, access control, and security reasoning.

---

## Future Architecture Considerations

If the project is expanded, future versions may evaluate:

- Authorized verifier roles
- Metadata update policies
- Cryptographic document verification
- Oracle-based verification
- Multi-signature administration
- Timelocked administrative operations
- NFT-based property representations
- Escrow or settlement contracts
- More advanced invariant suites
- Formal verification

Each additional capability should be introduced only after evaluating its security assumptions and effect on the existing trust model.