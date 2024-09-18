import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

// const LpAddress = "0xa9fe976c41bc8ce9cf89126bad9309adf1efb7e2";   // MAMA-USDT
const LpAddress = "0x335bb4d6d8166860e9cab64bdd3cb2249c9a469b";   // MAMA-MNT

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