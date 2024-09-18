import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let lmpoolContractAddresses = utils.getContractAddresses(
    networkName,
    `../lm-pool/deployments/${networkName}.json`
  );
  console.log("lm-pool contract addresses:", lmpoolContractAddresses);

  let contractAddresses = utils.getContractAddresses(networkName, "");

  const MasterChef = await ethers.getContractFactory("MasterChef");
  const masterChef = await MasterChef.attach(contractAddresses.MasterChef);

  // set lmpool deployer
  let LMPoolDeployer = await masterChef.LMPoolDeployer();
  console.log("master chef lm deploy:", LMPoolDeployer);

  if (LMPoolDeployer == "0x0000000000000000000000000000000000000000") {
    let setLmDeployer = await masterChef.setLMPoolDeployer(
      lmpoolContractAddresses.AgniLmPoolDeployer
    );
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

  // set incentive receiver
  const IncentivePool = await ethers.getContractFactory("ExtraIncentivePool");
  const incentivePool = await IncentivePool.attach(
    contractAddresses.ExtraIncentivePool
  );

  let incentivePoolReceiver = await incentivePool.receiver();
  console.log("incentivePool receiver:", incentivePoolReceiver);

  if (incentivePoolReceiver == "0x0000000000000000000000000000000000000000") {
    let setReceiver = await incentivePool.setReceiver(
      contractAddresses.IncentivePoolReceiver
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
