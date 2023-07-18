import { ethers } from "hardhat";
const utils = require("../common/utils");

const lmPoolDeployer = "0x44FaccB643Adf92AE208425EFbC45EE0Fedc9c3D";

async function main() {
  let contractAddresses = utils.getContractAddresses("");

  const MasterChef = await ethers.getContractFactory("MasterChef");
  const masterChef = await MasterChef.attach(contractAddresses.MasterChef);

  // set lmpool deployer
  let LMPoolDeployer = await masterChef.LMPoolDeployer();
  console.log("master chef lm deploy:", LMPoolDeployer);

  if (LMPoolDeployer == "0x0000000000000000000000000000000000000000") {
    let setLmDeployer = await masterChef.setLMPoolDeployer(lmPoolDeployer);
    console.log("set lmPoolDeployer tx: ", setLmDeployer.hash);
  }

  // set receiver
  let masterChefReceiver = await masterChef.receiver();
  console.log("masterChef receiver:", masterChefReceiver);

  if (masterChefReceiver == "0x0000000000000000000000000000000000000000") {
    let setReceiver = await masterChef.setReceiver(
      contractAddresses.MasterChefV3Receiver
    );
    console.log("setReceiver tx: ", setReceiver.hash);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
