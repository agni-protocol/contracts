import { ethers } from "hardhat";
const utils = require("../common/utils");

async function main() {
  let contractAddresses = utils.getContractAddresses("");

  const MasterChefV3Receiver = await ethers.getContractFactory("MasterChefV3Receiver");
  const masterChefRecevier = await MasterChefV3Receiver.attach(
    contractAddresses.MasterChefV3Receiver
  );

  let upkeepTx = await masterChefRecevier.upkeep(
    "100000000000000000000000",
    86400 * 30,
    true
  );
  console.log("upkeep tx:", upkeepTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
