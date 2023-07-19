import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

const LpAddress = "0xAbb213151ee053180348d9423F7F8dAf24F46F02";

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName,"");

  const MasterChef = await ethers.getContractFactory("MasterChef");
  const masterChef = await MasterChef.attach(contractAddresses.MasterChef);

  let owner = await  masterChef.owner();
  console.log("master chef owner:",owner);

  let LMPoolDeployer = await masterChef.LMPoolDeployer();
  console.log("master chef lm deploy:", LMPoolDeployer);

  let addPoolTx = await masterChef.add(10000, LpAddress, true);
  console.log("add pool tx: ", addPoolTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});