# Property Registry - Block Sherpa Assessment

Smart contract developed as part of the Block Sherpa technical assessment.

The project implements a decentralized property registry where users can register properties, store their price, and transfer property ownership on-chain.

## Features

- Register a property with an address and price
- Store the property's current owner
- Transfer property ownership
- Prevent unauthorized ownership transfers
- Prevent transfers to the zero address
- Emit events for property registration and ownership transfers
- Automated tests with Foundry
- Deployment script for Ethereum Sepolia

## Tech Stack

- Solidity
- Foundry
- Forge
- Cast
- Ethereum Sepolia

## Contract

**Network:** Ethereum Sepolia

**Contract address:**

`0xd6D8A3CCDc57b98768B32767A1e994d8Dbb05D18`

**Deployment transaction:**

`0xc6650fb846d1f3455e3e1f5ebb31f0bfb8f345b36732b081271768e9a749d3b5`

## Project Structure

```text
src/
|-- PropertyRegistry.sol

test/
|-- PropertyRegistry.t.sol

script/
|-- Deploy.s.sol
