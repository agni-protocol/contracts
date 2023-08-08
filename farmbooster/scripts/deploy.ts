import { ethers,upgrades } from "hardhat";
const utils = require("../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const FarmBooster = await ethers.getContractFactory("FarmBooster");
  const farmBooster = await FarmBooster.deploy();
  console.log("farmBooster", farmBooster.address);

  let contractAddresses = {
    FarmBooster: farmBooster.address,
  };
  await utils.writeContractAddresses(contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
