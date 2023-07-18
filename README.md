# agni-contracts
This is smart contracts for Agni Protocol.

## Deployments

1. Add Key in `.env` file. It's a private key of the account that will deploy the contracts and should be gitignored.
2. mantleTestnet `KEY_TESTNET` or mantle `KEY_MAINNET`
3. add `ETHERSCAN_API_KEY` in `.env` file. It's an API key for etherscan.
4. `yarn` in root directory
5. `NETWORK=$NETWORK yarn zx deploy.mjs` where `$NETWORK` is either  `mantleTestnet` or `hardhat` (for local testing)