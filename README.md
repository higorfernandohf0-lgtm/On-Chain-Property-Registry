# On-Chain Property Registry

A security-focused, production-oriented smart contract architecture for registering property records and transferring registry ownership on Ethereum.

Built with **Solidity, Foundry, OpenZeppelin, IPFS, fuzz testing, invariant testing, CI/CD, and a verified Sepolia deployment**.

> This project demonstrates an on-chain registry architecture. It does not establish or transfer legally recognized ownership of physical real estate without appropriate legal, institutional, and/or oracle integrations.

## Overview

The On-Chain Property Registry provides an auditable registry where users can:

- Register property records on-chain
- Reference off-chain metadata through IPFS-compatible URIs
- Transfer ownership of registered records
- Query registration information
- Pause state-changing operations during emergencies
- Separate protocol administration from individual property ownership

The architecture keeps descriptive property data and documents off-chain while storing registry-critical state and metadata references on Ethereum.

## Live Deployment

The current version of `PropertyRegistry` is deployed and verified on Ethereum Sepolia.

| Item | Value |
|---|---|
| Network | Ethereum Sepolia |
| Chain ID | `11155111` |
| Contract | `0x620977384C144C3Fd371930a388Dc7973F02D2eF` |
| Contract Status | Verified |
| Deployment Block | `11636171` |
| Deployment Gas | `1,244,446` |
| Deployment Transaction | `0xf2129ea31f536da0e58129af9ebaae3cf7bf10738b99d8d819137f55134bad6e` |

### Explorer

[View verified contract on Sepolia Etherscan](https://sepolia.etherscan.io/address/0x620977384C144C3Fd371930a388Dc7973F02D2eF#code)

[View deployment transaction](https://sepolia.etherscan.io/tx/0xf2129ea31f536da0e58129af9ebaae3cf7bf10738b99d8d819137f55134bad6e)

## On-Chain Demonstration

A demonstration property has been successfully registered on the deployed Sepolia contract and read back from contract state.

| Item | Value |
|---|---|
| Property ID | `0` |
| Owner | `0x54D7776D206f5C4EAF195d0eE460eEC4F4EdbBF8` |
| Registry Price | `100000000000000000000` |
| Registered At | `1788573384` |
| Metadata URI | `ipfs://bafkreico2sfhfgt5gp34ubc5li43tmpkdory3clyhf5xojorafq6ngt6qu` |
| Registration Block | `11637322` |
| Registration Gas Used | `186150` |
| Registration Transaction | `0x0584287c29fbce40026317abcbbfa8b4fd1fd4baa13c087bc8af05431f6e4625` |

[View registration transaction on Sepolia Etherscan](https://sepolia.etherscan.io/tx/0x0584287c29fbce40026317abcbbfa8b4fd1fd4baa13c087bc8af05431f6e4625)

### State Verification

After registration:

```text
propertyCount() = 1
```

Reading `getProperty(0)` returned:

```text
price:
100000000000000000000

owner:
0x54D7776D206f5C4EAF195d0eE460eEC4F4EdbBF8

registeredAt:
1788573384

propertyURI:
ipfs://bafkreico2sfhfgt5gp34ubc5li43tmpkdory3clyhf5xojorafq6ngt6qu
```

This provides an independently queryable demonstration that the property record was persisted in the deployed contract state.

## IPFS Metadata

The demonstration property references public, content-addressed metadata stored through IPFS.

### CID

```text
bafkreico2sfhfgt5gp34ubc5li43tmpkdory3clyhf5xojorafq6ngt6qu
```

### Canonical URI

```text
ipfs://bafkreico2sfhfgt5gp34ubc5li43tmpkdory3clyhf5xojorafq6ngt6qu
```

### Local SHA-256

```text
4ed48a729a7d33f7ca045d5a39b9b1ea1ba38d8978397b7725d10161e69a7e85
```

The metadata intentionally contains fictional demonstration information and no personal or legally sensitive property data.

The repository contains the corresponding example metadata at:

```text
metadata/example-property.json
```

Example schema:

```json
{
  "schemaVersion": "1.0.0",
  "name": "Example Property #1",
  "description": "Demonstration metadata for the On-Chain Property Registry portfolio project. This record does not represent legal ownership of real-world property.",
  "propertyType": "Residential",
  "location": {
    "city": "Example City",
    "region": "Example Region",
    "country": "Example Country"
  },
  "attributes": {
    "areaSquareMeters": 120,
    "bedrooms": 3,
    "bathrooms": 2
  },
  "documents": [],
  "verification": {
    "status": "unverified",
    "method": "portfolio-demo"
  }
}
```

## Core Smart Contract Features

### Property Registration

Any address can register a property record with:

- An IPFS-compatible metadata URI
- A non-zero registry price
- An automatically assigned property ID
- A registration timestamp
- `msg.sender` as the initial property owner

Each successful registration emits a `PropertyRegistered` event.

### Property Ownership Transfers

Only the current owner of a registered property can transfer its registry ownership.

The contract prevents:

- Transfers by unauthorized addresses
- Transfers to the zero address
- Transfers to the current owner
- Transfers of nonexistent properties

Each successful transfer emits a `PropertyOwnershipTransferred` event.

### Property Queries

Registered records can be retrieved through:

```solidity
getProperty(uint256 propertyId)
```

The total number of registered properties can be queried through:

```solidity
propertyCount()
```

### Emergency Pause

The protocol administrator can pause and unpause state-changing registry operations using OpenZeppelin `Pausable`.

While paused:

- New registrations are blocked
- Property ownership transfers are blocked
- Read-only queries remain available

### Two-Step Administrative Ownership

Administrative ownership uses OpenZeppelin `Ownable2Step`.

Instead of immediately replacing the administrator, ownership transfer requires the proposed new administrator to explicitly accept the role.

This reduces the risk of permanently transferring protocol administration to an incorrect address.

## Security Architecture

The contract applies defensive design decisions including:

- OpenZeppelin `Ownable2Step`
- OpenZeppelin `Pausable`
- Custom Solidity errors
- Checks before state changes
- Zero-address validation
- Non-zero price validation
- Empty metadata URI rejection
- Same-owner transfer rejection
- Explicit property existence validation
- Solidity 0.8 checked arithmetic
- No external calls in registration or property-transfer paths
- No ETH custody
- No token custody
- No arbitrary execution
- No private keys stored in source code

### Reentrancy Design Decision

`ReentrancyGuard` is intentionally not used in the current implementation.

The registration and property-transfer execution paths do not:

- Call external contracts
- Transfer ERC-20 tokens
- Transfer NFTs
- Transfer ETH
- Execute callbacks

Adding a reentrancy guard to the current call graph would therefore introduce additional deployment and runtime cost without protecting an existing external-call boundary.

Reentrancy protection must be reassessed if future versions introduce external interactions.

See [`docs/SECURITY.md`](docs/SECURITY.md) for additional security considerations.

## Administrative Separation

Protocol administration and individual property ownership are intentionally separate concepts.

The protocol administrator can:

- Pause the registry
- Unpause the registry
- Initiate administrative ownership transfer

The protocol administrator cannot arbitrarily seize a registered property through the current contract interface.

Individual property transfers remain controlled by the current property owner.

## Testing

The project uses Foundry for unit, fuzz, and stateful invariant testing.

Current test suite:

```text
29 tests passed
0 failed
0 skipped
```

### Unit Testing

Tests cover core behavior including:

- Property registration
- Property retrieval
- Property count
- Property ownership transfer
- Event emission
- Pause behavior
- Unpause behavior
- Administrative access control
- Two-step administrative ownership

### Negative Testing

Failure conditions include:

- Nonexistent property IDs
- Unauthorized transfers
- Empty property URIs
- Zero prices
- Zero-address ownership transfers
- Same-owner transfers
- Unauthorized pause attempts

### Fuzz Testing

Fuzz tests exercise the contract using dynamically generated inputs rather than relying exclusively on predefined examples.

Coverage includes fuzzed:

- Property registration
- Prices
- Metadata URIs
- Ownership transfers
- User addresses

### Invariant Testing

Stateful invariant testing uses a dedicated handler to execute sequences of registry operations and continuously verify safety properties.

The invariant suite verifies that:

- Registered property owners are never the zero address
- Registered property prices are never zero
- Registered property URIs are never empty
- Every registered property remains readable

Invariant configuration:

```toml
[invariant]
runs = 64
depth = 32
fail_on_revert = false
```

This complements traditional unit tests by testing properties that should remain true across sequences of state transitions.

## Gas Optimization

Gas optimization was approached through architecture rather than unsafe micro-optimizations.

An unnecessary reentrancy guard was removed after analyzing the contract call graph.

Measured results:

| Metric | Before | After |
|---|---:|---:|
| Deployment Gas | 1,290,158 | 1,244,446 |
| Deployment Bytecode | 6,153 bytes | 6,035 bytes |
| `registerProperty` avg. | 148,740 gas | 146,333 gas |
| `transferPropertyOwnership` avg. | 36,289 gas | 33,887 gas |

Measured improvements:

- Deployment gas: approximately **3.5% lower**
- Deployment bytecode: approximately **1.9% smaller**
- Average registration gas: approximately **1.6% lower**
- Average ownership-transfer gas: approximately **6.6% lower**

The optimization preserves the existing security model because the affected execution paths contain no external calls.

See [`docs/GAS_OPTIMIZATION.md`](docs/GAS_OPTIMIZATION.md).

## Architecture

High-level data flow:

```text
                   Ethereum
                      |
                      v
               PropertyRegistry
               /      |       \
              /       |        \
         owner      price    registeredAt
              \
               \
             propertyURI
                  |
                  v
             IPFS Network
                  |
                  v
        Content-addressed JSON
```

Registration flow:

```text
User
 |
 | registerProperty(propertyURI, price)
 |
 v
PropertyRegistry
 |
 +--> validates URI
 |
 +--> validates price
 |
 +--> assigns property ID
 |
 +--> stores owner
 |
 +--> stores timestamp
 |
 +--> stores metadata URI
 |
 +--> emits PropertyRegistered
```

Ownership-transfer flow:

```text
Current Property Owner
 |
 | transferPropertyOwnership(propertyId, newOwner)
 |
 v
PropertyRegistry
 |
 +--> verifies property exists
 |
 +--> verifies caller owns property
 |
 +--> validates new owner
 |
 +--> updates ownership
 |
 +--> emits PropertyOwnershipTransferred
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Storage Model

Each property is represented by:

```solidity
struct Property {
    uint256 price;
    address owner;
    uint40 registeredAt;
    string propertyURI;
}
```

Properties are stored internally using:

```solidity
mapping(uint256 propertyId => Property property) private _properties;
```

Property IDs are sequentially generated through `_nextPropertyId`.

Because registered properties cannot currently be deleted, the condition:

```text
propertyId < propertyCount()
```

also represents the existence domain of registered records.

## Deployment Provenance

The contract stores the deployment chain ID as an immutable value:

```solidity
uint256 public immutable DEPLOYMENT_CHAIN_ID;
```

During construction:

```solidity
DEPLOYMENT_CHAIN_ID = block.chainid;
```

The current Sepolia deployment returns:

```text
11155111
```

This provides explicit deployment-network provenance directly from contract state.

## Technology Stack

- Solidity `^0.8.20`
- Foundry
- Forge
- Cast
- OpenZeppelin Contracts `v5.4.0`
- IPFS
- Git
- GitHub
- GitHub Actions
- Ethereum Sepolia

## Project Structure

```text
.
├── .github/
│   └── workflows/
│       └── test.yml
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── GAS_OPTIMIZATION.md
│   └── SECURITY.md
│
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
│
├── metadata/
│   └── example-property.json
│
├── script/
│   └── Deploy.s.sol
│
├── src/
│   └── PropertyRegistry.sol
│
├── test/
│   ├── invariant/
│   │   ├── PropertyRegistryHandler.sol
│   │   └── PropertyRegistryInvariant.t.sol
│   └── PropertyRegistry.t.sol
│
├── .env.example
├── .gitignore
├── .gitmodules
├── foundry.lock
├── foundry.toml
└── README.md
```

## Build and Test

### Clone

Clone the repository including Git submodules:

```bash
git clone --recurse-submodules https://github.com/higorfernandohf0-lgtm/On-Chain-Property-Registry.git
cd On-Chain-Property-Registry
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

### Build

```bash
forge build
```

On systems where Foundry is not available globally:

```bash
~/.foundry/bin/forge.exe build
```

### Run Tests

```bash
forge test
```

Or:

```bash
~/.foundry/bin/forge.exe test
```

### Verbose Tests

```bash
forge test -vvv
```

### Gas Report

```bash
forge test --gas-report
```

### Formatting

```bash
forge fmt --check
```

### Contract Sizes

```bash
forge build --sizes
```

## Environment Configuration

Use `.env.example` as the template for local configuration:

```env
SEPOLIA_RPC_URL=
INITIAL_OWNER=
ETHERSCAN_API_KEY=
```

The real `.env` file must remain local and must never be committed.

Never commit or publish:

- Wallet private keys
- Seed phrases
- Keystore passwords
- RPC credentials
- Explorer API credentials
- `.env` files containing credentials

For transaction signing, encrypted Foundry keystores are preferred over storing raw private keys in project files.

## Deployment

The Foundry deployment script reads the administrative owner from the environment:

```solidity
address initialOwner = vm.envAddress("INITIAL_OWNER");

vm.startBroadcast();

registry = new PropertyRegistry(initialOwner);

vm.stopBroadcast();
```

Example Sepolia deployment:

```bash
~/.foundry/bin/forge.exe script \
script/Deploy.s.sol:Deploy \
--rpc-url "$SEPOLIA_RPC_URL" \
--account sepolia-deployer \
--broadcast
```

The encrypted keystore password is entered interactively and should never be included directly in terminal commands.

## Contract Verification

The deployed contract source is verified on Sepolia Etherscan.

The verification includes the constructor argument corresponding to the initial administrative owner.

Verified contract:

```text
0x620977384C144C3Fd371930a388Dc7973F02D2eF
```

This allows reviewers to compare the published Solidity source with the deployed bytecode through the block explorer.

## Metadata Integrity Model

The project separates registry state from descriptive metadata.

### On-chain

Ethereum stores:

- Property ID
- Registry price
- Owner
- Registration timestamp
- Metadata URI

### Off-chain

IPFS stores descriptive metadata such as:

- Property type
- Demonstration location
- Demonstration attributes
- Verification metadata
- Document references

### Integrity

The metadata is content-addressed through an IPFS CID.

The example file also has a recorded SHA-256 checksum:

```text
4ed48a729a7d33f7ca045d5a39b9b1ea1ba38d8978397b7725d10161e69a7e85
```

If the underlying metadata content changes, the content-addressed reference is expected to change as well.

## Design Decisions

### Metadata Off-Chain

Property metadata may include descriptive information or documents that are inefficient and potentially inappropriate to store directly on Ethereum.

The contract therefore stores only a metadata URI.

### No ETH Custody

The `price` field represents registry valuation data.

It does **not** represent ETH transferred to the contract.

`registerProperty` is not a payment function, and the current contract does not operate as:

- Escrow
- Marketplace
- Payment processor
- Token vault

### Permissionless Registration

The current implementation intentionally allows users to self-register property records.

This demonstrates the smart contract registry architecture without pretending to provide real-world identity or legal verification.

A real institutional implementation would likely require additional components such as:

- Authorized registrars
- Identity verification
- Legal validation
- Government registry integration
- Oracle infrastructure
- Attestation systems

### Immutable Registration History

Registered properties cannot currently be deleted.

This simplifies existence guarantees and preserves an auditable registry history.

### Metadata Updates

The current contract does not provide a metadata update function.

This makes the registered URI stable under the current interface.

A future implementation could introduce an explicit metadata-update policy with authorization and event emission if mutable records become a requirement.

## Threat Model and Limitations

This repository demonstrates smart contract engineering and should not be interpreted as a legally authoritative real-estate system.

Current limitations include:

- No external smart contract audit
- No formal verification
- No real-world identity verification
- No government registry integration
- No oracle-based property validation
- No legal-title enforcement
- No document confidentiality layer
- Permissionless self-registration
- No institutional registrar role
- No dispute-resolution mechanism
- Metadata authenticity depends on the surrounding verification process

For these reasons, the project is described as **production-oriented**, not production-ready.

## CI/CD

GitHub Actions automatically validates repository changes.

The CI workflow performs:

```text
forge --version
forge fmt --check
forge build --sizes
forge test -vvv
```

Git submodules are checked out recursively so Foundry and OpenZeppelin dependencies are available during CI execution.

## Security Practices

Development and deployment follow several operational-security principles:

1. Private keys are not stored in source code.
2. Seed phrases are never required by the project.
3. `.env` is excluded from version control.
4. Deployment signing uses an encrypted local Foundry keystore.
5. API credentials remain outside tracked source files.
6. Public addresses, transaction hashes, contract addresses, and IPFS CIDs may be documented because they are public identifiers.
7. Third-party code should be reviewed before execution.
8. Unknown scripts and repositories should never receive wallet secrets.
9. Testnet wallets should remain separated from wallets holding real funds.
10. Dependency sources should be verified before installation.

## CI and Reproducibility

A reviewer can independently:

1. Clone the repository.
2. Initialize the Git submodules.
3. Compile the contracts.
4. Run the complete Foundry test suite.
5. Inspect gas measurements.
6. Inspect the verified Sepolia contract.
7. Inspect the registration transaction.
8. Query the deployed contract.
9. Retrieve the metadata using its IPFS CID.
10. Compare the metadata against the repository example.

This creates a reproducible portfolio artifact rather than relying only on screenshots or written claims.

## Roadmap

Potential future extensions include:

- Authorized verifier roles
- Property verification attestations
- Metadata update policies
- Multi-signature protocol administration
- Oracle integrations
- Institutional registry adapters
- Additional stateful invariants
- Static analysis with Slither
- Automated security checks in CI
- Deployment manifests
- Additional testnet demonstrations
- Minimal read-only frontend built from a clean codebase

## Disclaimer

This repository is an educational and portfolio smart contract engineering project.

The demonstration property metadata is fictional.

The smart contract records on-chain registry state but does not independently prove:

- Physical possession
- Legal ownership
- Government recognition
- Authenticity of submitted real-world documents

Any real-world property system would require substantial legal, identity, security, governance, and institutional infrastructure beyond the smart contract itself.

## Author

**Higor Fernando**

Web3 Research / On-Chain Analytics / Solidity

GitHub: [higorfernandohf0-lgtm](https://github.com/higorfernandohf0-lgtm)

---

Built as a smart contract engineering portfolio project focused on **security, testing, on-chain verifiability, metadata integrity, and auditable design**.
