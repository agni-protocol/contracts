import { ethers,upgrades } from "hardhat";
const utils = require("../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const Multicall3 = await ethers.getContractFactory("Multicall3");
  const multicall3 = await Multicall3.deploy();
  console.log("multicall3", multicall3.address);

  let contractAddresses = {
    Multicall3: multicall3.address
  };
  await utils.writeContractAddresses(contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
