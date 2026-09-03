# Gas Optimization

## Overview

Gas optimization in the On-Chain Property Registry focuses on reducing unnecessary execution and deployment costs without sacrificing readability, safety, or maintainability.

The project does not pursue micro-optimizations that would make the contract significantly harder to understand or audit.

Instead, optimizations are based on measurable architectural decisions and Foundry gas reports.

---

## Optimization Principles

The contract follows several gas-conscious design principles:

- Keep the contract architecture small
- Minimize unnecessary storage
- Pack compatible storage values
- Use custom errors instead of long revert strings
- Avoid unnecessary external calls
- Avoid unnecessary security modifiers
- Use immutable values where appropriate
- Cache storage values when reused
- Avoid unnecessary state transitions
- Measure changes using Foundry gas reports

Gas optimization is treated as an engineering tradeoff rather than a goal that overrides security or clarity.

---

## Property Storage Layout

The property structure is:

```solidity
struct Property {
    uint256 price;
    address owner;
    uint40 registeredAt;
    string propertyURI;
}
```

The ordering intentionally allows:

```solidity
address owner;
uint40 registeredAt;
```

to share a storage slot.

An EVM storage slot contains 32 bytes.

An address requires 20 bytes and `uint40` requires 5 bytes.

Their combined fixed-size representation therefore fits within a single storage slot.

This reduces storage usage compared with storing the timestamp as a full `uint256`.

---

## Timestamp Width

The registration timestamp is stored as:

```solidity
uint40 registeredAt;
```

instead of:

```solidity
uint256 registeredAt;
```

The timestamp is informational and does not require the full `uint256` range.

Using a smaller integer also allows the timestamp to be packed with the property owner's address.

The implementation avoids custom assembly or manual bit manipulation, keeping the optimization simple and reviewable.

---

## Immutable Deployment Chain ID

The deployment chain ID is declared as:

```solidity
uint256 public immutable DEPLOYMENT_CHAIN_ID;
```

and initialized during construction:

```solidity
DEPLOYMENT_CHAIN_ID = block.chainid;
```

Because the value never changes after deployment, `immutable` avoids treating it as a normal mutable storage variable.

This provides deployment provenance without requiring a regular storage read for every access.

---

## Custom Errors

Contract-specific validation uses custom errors.

Example:

```solidity
error InvalidPrice(uint256 price);
```

instead of a long revert string such as:

```solidity
require(price > 0, "Property price must be greater than zero");
```

Custom errors provide structured failure information while generally reducing deployed bytecode and revert-related gas compared with long string messages.

---

## Storage Caching

During property ownership transfer, the property is loaded as a storage reference:

```solidity
Property storage property =
    _getPropertyStorage(propertyId);
```

The current owner is then cached:

```solidity
address currentOwner = property.owner;
```

The cached value is reused for:

- Authorization validation
- Same-owner validation
- Event emission

This keeps the logic explicit while avoiding unnecessary repeated access patterns.

---

## Sequential Property IDs

Property IDs use a simple sequential counter:

```solidity
uint256 private _nextPropertyId;
```

Registration assigns:

```solidity
propertyId = _nextPropertyId;
```

and then increments the counter:

```solidity
_nextPropertyId = propertyId + 1;
```

This avoids more complex identifier generation mechanisms.

The project currently keeps Solidity's default checked arithmetic rather than using `unchecked`.

The additional theoretical micro-optimization from `unchecked` was not considered valuable enough to justify removing the compiler's default overflow protection.

---

## Property Existence Check

Because:

- Property IDs are sequential
- IDs begin from zero
- Properties cannot currently be deleted

existence can be validated using:

```solidity
if (propertyId >= _nextPropertyId) {
    revert PropertyNotFound(propertyId);
}
```

This avoids maintaining an additional existence mapping or boolean field.

If deletion or sparse identifiers are introduced later, this optimization and its underlying invariant must be reconsidered.

---

## ReentrancyGuard Removal

An earlier version of the contract inherited OpenZeppelin's `ReentrancyGuard` and applied `nonReentrant` to:

```text
registerProperty
transferPropertyOwnership
```

The contract's external interaction surface was subsequently reviewed.

Neither function:

- Transfers ETH
- Transfers tokens
- Calls external contracts
- Executes callbacks
- Invokes user-controlled hooks

Therefore, the guard was not protecting an existing reentrant external call path.

`ReentrancyGuard` was removed and the complete test suite was executed again.

The result was:

```text
29 tests passed
0 tests failed
```

The core contract also retained full measured coverage:

```text
Lines:       100%
Statements:  100%
Branches:    100%
Functions:   100%
```

---

## Measured ReentrancyGuard Optimization

Foundry gas reports were collected before and after removing the unnecessary guard.

### Deployment

| Metric | Before | After | Difference |
|---|---:|---:|---:|
| Deployment Gas | 1,290,158 | 1,244,446 | -45,712 |
| Deployment Size | 6,153 bytes | 6,035 bytes | -118 bytes |

Deployment gas decreased by approximately **3.5%**.

Deployment bytecode decreased by approximately **1.9%**.

---

## Function Gas Comparison

### `registerProperty`

Average measured gas:

```text
Before: 148,740
After:  146,333
```

Difference:

```text
-2,407 gas
```

Approximate reduction:

```text
1.6%
```

### `transferPropertyOwnership`

Average measured gas:

```text
Before: 36,289
After:  33,887
```

Difference:

```text
-2,402 gas
```

Approximate reduction:

```text
6.6%
```

This was a useful optimization because it simultaneously:

- Reduced bytecode
- Reduced deployment gas
- Reduced execution gas
- Removed unnecessary state-management logic
- Reduced contract complexity
- Preserved all existing tests
- Preserved full core contract coverage

---

## Current Gas Report

After the optimization, the main contract produced the following representative Foundry gas measurements:

| Operation | Average Gas |
|---|---:|
| `DEPLOYMENT_CHAIN_ID` | 392 |
| `acceptOwnership` | 27,394 |
| `getProperty` | 14,965 |
| `owner` | 2,559 |
| `pause` | 41,385 |
| `paused` | 2,569 |
| `pendingOwner` | 2,581 |
| `propertyCount` | 2,476 |
| `registerProperty` | 146,333 |
| `transferOwnership` | 48,108 |
| `transferPropertyOwnership` | 33,887 |
| `unpause` | 24,554 |

Measured deployment:

```text
Deployment Gas:  1,244,446
Deployment Size: 6,035 bytes
```

Gas measurements may vary with compiler configuration, optimizer settings, calldata, storage state, and test execution conditions.

These values should therefore be treated as measurements from the project's current Foundry configuration rather than universal constants.

---

## Why ReentrancyGuard Was Not Kept as Defense-in-Depth

Security controls should correspond to actual threat surfaces.

Adding security modifiers without analyzing whether the associated vulnerability is reachable can:

- Increase gas costs
- Increase bytecode size
- Add state and execution complexity
- Create a false impression that security is achieved by accumulating modifiers

For the current architecture, minimizing the external interaction surface is stronger and simpler than adding a reentrancy guard to functions that make no external calls.

If external interactions are added in the future, the decision must be reviewed again.

---

## Optimizations Intentionally Avoided

The project intentionally avoids several aggressive micro-optimizations.

### Excessive `unchecked`

The project does not broadly disable Solidity's checked arithmetic simply to save small amounts of gas.

### Assembly

The contract currently does not use inline assembly for ordinary registry operations.

Assembly could make the code harder to audit and maintain without providing a meaningful benefit for the current use case.

### Complex Bit Packing

The project benefits from Solidity's normal struct packing instead of manually packing multiple values into custom bit fields.

### Reduced Error Information

Custom errors are used for efficiency, but useful contextual information is retained where appropriate.

For example:

```solidity
error NotPropertyOwner(
    uint256 propertyId,
    address caller,
    address currentOwner
);
```

This provides useful debugging and integration information rather than minimizing error data at all costs.

---

## Optimization vs Security

Gas reduction is not considered successful if it materially weakens security.

The project prioritizes:

```text
Correctness
    ↓
Security
    ↓
Clarity
    ↓
Gas Optimization
```

Optimizations should preserve the contract's security properties and remain understandable during manual review.

---

## Measurement Methodology

Gas measurements are generated with Foundry using:

```bash
forge test --gas-report
```

Functional correctness is validated separately through:

```bash
forge test
```

and coverage through:

```bash
forge coverage
```

Coverage execution may use different compiler settings for instrumentation and should not be used as the primary gas benchmark.

Gas comparisons should be made using equivalent compiler and Foundry configurations.

---

## Future Optimization Work

Potential future optimization work includes:

- Measuring compiler optimizer configurations
- Evaluating optimizer run counts
- Comparing deployment and runtime tradeoffs
- Monitoring contract size during feature additions
- Adding gas snapshots for regression detection
- Benchmarking future metadata operations
- Reviewing new external integrations individually

Optimizations should continue to be supported by measurements rather than assumptions.

---

## Conclusion

The current gas optimization strategy favors measurable improvements with low architectural risk.

The removal of unnecessary reentrancy protection demonstrated this approach:

```text
Deployment Gas
1,290,158 -> 1,244,446

Deployment Size
6,153 -> 6,035 bytes

registerProperty Average
148,740 -> 146,333 gas

transferPropertyOwnership Average
36,289 -> 33,887 gas
```

The optimization retained all 29 tests and full measured coverage of the core `PropertyRegistry.sol` contract.

This provides a reproducible example of using testing and gas measurement together to guide smart contract engineering decisions.