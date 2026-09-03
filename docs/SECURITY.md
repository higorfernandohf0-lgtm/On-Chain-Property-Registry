# Security

## Overview

Security is a primary design consideration of the On-Chain Property Registry.

The contract is intentionally kept small and avoids unnecessary external interactions, payment logic, upgradeability, and complex dependencies.

This document describes the current security model, trust assumptions, implemented protections, known limitations, and areas that would require additional review before a production deployment.

> This project has not undergone a professional third-party security audit.

---

## Security Principles

The contract follows several security-oriented design principles:

- Minimize the external call surface
- Keep administrative and property ownership separate
- Validate state-changing inputs
- Reject invalid ownership transitions
- Provide an emergency pause mechanism
- Use established OpenZeppelin access-control components
- Prefer explicit custom errors
- Test expected failures as well as successful operations
- Exercise state transitions through fuzz and invariant testing
- Avoid storing secrets or sensitive personal information on-chain

---

## Administrative Access Control

Administrative ownership is provided through OpenZeppelin's `Ownable2Step`.

The administrative owner can:

- Pause the contract
- Unpause the contract
- Initiate administrative ownership transfer

The administrative owner cannot directly transfer another user's property record.

This separation limits administrative authority over individual registry entries.

---

## Two-Step Ownership Transfer

Administrative ownership transfer requires two operations:

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

This protects against accidentally transferring administrative ownership to an address that cannot or should not control the contract.

The tests verify that administrative privileges move only after the pending owner accepts ownership.

---

## Property Ownership Authorization

Property ownership transfers are restricted to the current property owner.

Before a transfer is completed, the contract verifies:

1. The destination is not the zero address.
2. The property exists.
3. The caller is the current property owner.
4. The destination is different from the current owner.

Unauthorized transfers revert using a custom error containing the property ID, caller, and current owner.

---

## Input Validation

### Empty Metadata URI

Property registration rejects an empty `propertyURI`.

This prevents creation of property records without a metadata reference.

The contract does not currently validate whether the URI actually resolves to IPFS or whether its referenced content is valid.

---

### Zero Price

Property registration rejects a price of zero.

The price is a registry valuation field only.

It does not trigger an ETH or token payment.

---

### Zero Address

Property ownership cannot be transferred to:

```solidity
address(0)
```

This prevents a property record from becoming owned by the zero address through the transfer function.

OpenZeppelin's `Ownable` implementation also rejects a zero address as the initial administrative owner.

---

### Same-Owner Transfer

The contract rejects transfers where:

```text
newOwner == currentOwner
```

This prevents meaningless state transitions and unnecessary event emissions.

---

## Property Existence

Properties receive sequential IDs.

The contract currently does not support property deletion.

A property is therefore considered valid when:

```text
propertyId < _nextPropertyId
```

This relationship is relied upon by `_getPropertyStorage`.

If deletion, sparse IDs, migration, or another ID-generation mechanism is introduced in the future, this security assumption must be reviewed.

---

## Emergency Pause

The contract uses OpenZeppelin's `Pausable`.

When the contract is paused:

- New property registrations are blocked.
- Property ownership transfers are blocked.

Read operations remain available.

Only the administrative owner can pause or unpause the registry.

The pause mechanism is intended as an emergency control rather than a normal operating state.

---

## Reentrancy Analysis

The contract intentionally does not currently inherit `ReentrancyGuard`.

The relevant state-changing property functions do not:

- Transfer ETH
- Transfer ERC-20 tokens
- Transfer NFTs
- Call arbitrary external contracts
- Invoke user-controlled callbacks
- Execute hooks

Without an external interaction during these operations, the current implementation does not expose the typical reentrant call path that `ReentrancyGuard` is designed to protect.

An earlier implementation included `ReentrancyGuard` as defense-in-depth.

It was removed after reviewing the external interaction surface because it added bytecode and execution cost without protecting an existing external call path.

Reentrancy risk must be reassessed if future versions introduce payments, external contract calls, token interactions, callbacks, hooks, or other external execution.

---

## Checks and State Changes

State-changing functions validate their required conditions before modifying registry state.

For property transfers, the contract validates the destination, property existence, and authorization before changing the stored owner.

The current contract performs no external interaction after the state change.

Future external integrations should follow an appropriate checks-effects-interactions design and receive a new reentrancy review.

---

## Custom Errors

Contract-specific validation uses custom errors such as:

```solidity
error PropertyNotFound(uint256 propertyId);

error NotPropertyOwner(
    uint256 propertyId,
    address caller,
    address currentOwner
);

error ZeroAddress();
error EmptyPropertyURI();
error InvalidPrice(uint256 price);
error SameOwner(address owner);
```

Custom errors provide explicit failure conditions without relying on long revert strings.

OpenZeppelin components continue to use their own defined errors.

---

## Integer Safety

The contract uses Solidity `^0.8.20`.

Solidity 0.8.x performs checked arithmetic by default.

The property ID counter is incremented using checked arithmetic:

```solidity
_nextPropertyId = propertyId + 1;
```

No `unchecked` block is currently used for this operation.

---

## Timestamp

The registration timestamp is stored as:

```solidity
uint40 registeredAt;
```

and assigned from:

```solidity
uint40(block.timestamp)
```

The reduced integer width is used for storage packing.

The timestamp is informational registry metadata and is not currently used for security-critical authorization or financial calculations.

As with all EVM timestamps, `block.timestamp` should not be treated as a source of cryptographic randomness.

---

## Storage Packing

The `Property` struct contains:

```solidity
struct Property {
    uint256 price;
    address owner;
    uint40 registeredAt;
    string propertyURI;
}
```

`owner` and `registeredAt` can share a storage slot because their combined fixed-size representation fits within 32 bytes.

This optimization reduces storage usage without introducing bit-level assembly or custom packing logic.

Avoiding unnecessary assembly keeps the implementation easier to review.

---

## External Call Surface

The current property registry logic has a deliberately small external interaction surface.

Property registration and property ownership transfer do not call external contracts.

This reduces exposure to vulnerabilities involving:

- Reentrancy
- Malicious fallback functions
- Unexpected token behavior
- External callback execution
- Cross-contract state assumptions

Any future external integration should trigger a new threat-model review.

---

## Metadata Security

`propertyURI` is an off-chain reference.

The contract guarantees only that the supplied string is non-empty.

It does not guarantee:

- That the URI uses IPFS
- That the content exists
- That the content remains available
- That the metadata is truthful
- That documents are authentic
- That referenced files are safe
- That the metadata represents a legally recognized property

Applications consuming the URI must treat referenced content as untrusted input.

Frontends and backend services should not automatically execute, render, or download arbitrary content without appropriate validation.

---

## Sensitive Information

Sensitive personal information should not be stored directly on-chain.

Blockchain data is generally public and difficult or impossible to remove after publication.

Examples of information that should not be placed directly in registry metadata without careful privacy analysis include:

- Personal identification documents
- Private addresses associated with individuals
- Authentication credentials
- Private keys
- Seed phrases
- API keys
- Confidential legal documents

Private keys and seed phrases must never be committed to this repository.

---

## Smart Contract Administrator

The administrative owner represents a privileged role.

A compromised administrator could pause the registry and disrupt state-changing operations.

For a real production deployment, administrative control should be evaluated for migration to stronger operational controls such as:

- Hardware-backed signing
- Multi-signature wallets
- Timelocks
- Role separation
- Monitored administrative transactions

These controls are outside the current portfolio implementation.

---

## Trust Assumptions

The current contract assumes that users are responsible for the property records they create.

The contract does not prove that a user legally owns the physical property represented by a record.

The system does not currently include:

- Identity verification
- Government verification
- Authorized property verifiers
- Legal ownership validation
- Document authenticity verification
- Oracle-based real-world validation

Therefore, on-chain ownership in this contract represents control of the registry entry.

It must not automatically be interpreted as legally enforceable ownership of a physical asset.

---

## Testing Strategy

The contract is tested using Foundry.

The current test strategy includes:

- Unit testing
- Authorization testing
- Revert testing
- Event testing
- Pause-state testing
- Administrative ownership testing
- Fuzz testing
- Stateful invariant testing

The current core contract reaches:

```text
Lines:       100%
Statements:  100%
Branches:    100%
Functions:   100%
```

under the project's current coverage suite.

High coverage demonstrates that the measured code paths are exercised by tests.

It does not prove the absence of vulnerabilities.

---

## Fuzz Testing

Fuzz tests exercise property registration and ownership transfer using generated inputs.

Input constraints are applied using Foundry utilities such as `vm.assume` and `bound` where appropriate.

Fuzzing helps test a broader input space than fixed example-based unit tests.

---

## Invariant Testing

Stateful invariant testing repeatedly invokes actions through a dedicated handler.

The current invariant suite verifies that:

- Registered property owners never become the zero address
- Registered property prices never become zero
- Registered property URIs never become empty
- Registered properties remain readable

Invariant testing helps evaluate properties that should remain true across sequences of valid state transitions.

---

## Known Limitations

The following are known limitations of the current implementation:

1. Anyone can register a property record.
2. Physical property ownership is not verified.
3. Metadata authenticity is not verified on-chain.
4. Metadata availability is not guaranteed.
5. Property records cannot currently be deleted.
6. Property metadata cannot currently be updated.
7. The contract does not provide escrow or settlement.
8. The contract does not process payments.
9. The contract has not undergone a professional third-party audit.
10. Administrative control currently depends on a single owner unless the deployed owner itself is a multisig or similar contract.

These limitations are intentionally documented rather than hidden behind claims of production readiness.

---

## Dependency Security

The project uses OpenZeppelin Contracts for established access-control and pause functionality.

Dependencies should be installed only from verified official sources.

Dependency versions should be reviewed before upgrades because a dependency update can change behavior, interfaces, bytecode, or security assumptions.

Untrusted repositories, scripts, packages, or copied smart contract code should not be executed without review.

---

## Deployment Security

Production private keys must never be:

- Hardcoded into Solidity
- Stored in source files
- Committed to Git
- Published in `.env.example`
- Shared in screenshots or logs

Deployment configuration should use environment variables or secure signing mechanisms.

For development and testnet deployment, dedicated test-only wallets should be used.

A production deployment would require a separate operational security review.

---

## Security Review Status

Current security work includes:

- Manual architecture review
- Access-control tests
- Failure-path tests
- Fuzz testing
- Stateful invariant testing
- Gas analysis
- Full core contract coverage

Planned additional security work may include:

- Static analysis
- Additional adversarial tests
- Higher-intensity invariant runs
- Testnet validation
- Source verification
- Manual post-deployment checks

The project should not be described as professionally audited unless an independent qualified security review is actually completed.