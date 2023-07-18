# Agni Periphery

This repository contains the periphery smart contracts for the Agni Protocol.
For the lower level core contracts, see the [core](../core/)
repository.

## Local deployment

In order to deploy this code to a local testnet, you should install the npm package
`@agniswap/periphery`
and import bytecode imported from artifacts located at
`@agniswap/periphery/artifacts/contracts/*/*.json`.
For example:

```typescript
import {
  abi as SWAP_ROUTER_ABI,
  bytecode as SWAP_ROUTER_BYTECODE,
} from "@agniswap/periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json";

// deploy the bytecode
```

This will ensure that you are testing against the same bytecode that is deployed to
mainnet and public testnets, and all Agni code will correctly interoperate with
your local deployment.

## Using solidity interfaces

The Agni periphery interfaces are available for import into solidity smart contracts
via the npm artifact `@agniswap/periphery`, e.g.:

```solidity
import '@agniswap/periphery/contracts/interfaces/ISwapRouter.sol';

contract MyContract {
  ISwapRouter router;

  function doSomethingWithSwapRouter() {
    // router.exactInput(...);
  }
}

```
