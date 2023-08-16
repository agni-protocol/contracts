import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName,"");

  // master chef 
  const MasterChefV3Receiver = await ethers.getContractFactory("MasterChefV3Receiver");
  const masterChefRecevier = await MasterChefV3Receiver.attach(
    contractAddresses.MasterChefV3Receiver
  );

  let upkeepTx = await masterChefRecevier.upkeep(
    "20000000000000000000", // 20 WMNT
    86400 * 30,
    true
  );
  console.log("upkeep tx:", upkeepTx.hash);

  // incentive pool
  const IncentivePoolReceiver = await ethers.getContractFactory(
    "IncentivePoolReceiver"
  );
  const extraIncentivePoolReceiver = await IncentivePoolReceiver.attach(
    contractAddresses.IncentivePoolReceiver
  );

   upkeepTx = await extraIncentivePoolReceiver.upkeep(
     "10000000000",
     86400 * 30
   );
   console.log("upkeep tx:", upkeepTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
