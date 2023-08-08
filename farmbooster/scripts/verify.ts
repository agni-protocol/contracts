const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  let networkName = network.name;
  let contractAddresses = utils.getContractAddresses(networkName,"");
  console.log("multicall3 contract addresses:", contractAddresses);

  await hre.run("verify:verify", {
    address: contractAddresses.Multicall3,
    contract: "contracts/Multicall3.sol:Multicall3",
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
