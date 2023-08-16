import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

const LpAddress = "0xf9a8ea5d7d73b284853bcbba1e163c615ba47b2b";  // MAMA / WMNT 1%

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
  console.log("master chef add pool tx: ", addPoolTx.hash);

  // add incentive pool
  const IncentivePool = await ethers.getContractFactory("ExtraIncentivePool");
  const incentivePool = await IncentivePool.attach(
    contractAddresses.ExtraIncentivePool
  );
  addPoolTx = await incentivePool.add(LpAddress,10000);
  console.log("incentive add pool tx: ", addPoolTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});