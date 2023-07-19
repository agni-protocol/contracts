import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import dotenv from "dotenv";
dotenv.config();

const owner =
  process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY : '';
const keeper =
  process.env.KEEPER_PRIVATE_KEY !== undefined ? process.env.KEEPER_PRIVATE_KEY : "";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    mantleTestnet: {
      url: process.env.MANTLE_TESTNET_URL || "",
      accounts: [owner, keeper],
    },
    mantleMainnet: {
      url: process.env.MANTLE_URL || "",
      accounts: [owner, keeper],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.MANTLESCAN_API_KEY,
    customChains: [
      {
        network: "mantleTestnet",
        chainId: 5001,
        urls: {
          apiURL: "https://explorer.testnet.mantle.xyz/api",
          browserURL: "https://rpc.testnet.mantle.xyz",
        },
      },
      {
        network: "mantleMainnet",
        chainId: 5000,
        urls: {
          apiURL: "https://explorer.mantle.xyz/api",
          browserURL: "https://explorer.mantle.xyz/",
        },
      },
    ],
  },
};

export default config;
