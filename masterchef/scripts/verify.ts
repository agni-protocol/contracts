const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let peripheryContractAddresses = utils.getContractAddresses(
    networkName,`../periphery/deployments/${networkName}.json`
  );
  console.log("periphery contract addresses:", peripheryContractAddresses);

  let contractAddresses = utils.getContractAddresses(networkName, "");
  console.log("WMNT addresses:", contractAddresses.WMNT);
  console.log("AGNI addresses:", contractAddresses.MasterChefToken);

  await hre.run("verify:verify", {
    address: contractAddresses.MasterChef,
    contract: "contracts/MasterChef.sol:MasterChef",
    constructorArguments: [
      contractAddresses.MasterChefToken,
      peripheryContractAddresses.NonfungiblePositionManager,
      contractAddresses.WMNT,
    ],
  });

   await hre.run("verify:verify", {
     address: contractAddresses.ExtraIncentivePool,
     contract: "contracts/ExtraIncentivePool.sol:ExtraIncentivePool",
     constructorArguments: [
       contractAddresses.IncentiveToken,
       contractAddresses.MasterChef,
     ],
   });

  await hre.run("verify:verify", {
    address: contractAddresses.MasterChefV3Receiver,
    contract:
      "contracts/receiver/MasterChefV3Receiver.sol:MasterChefV3Receiver",
    constructorArguments: [contractAddresses.MasterChef, contractAddresses.MasterChefToken],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.IncentivePoolReceiver,
    contract:
      "contracts/receiver/IncentivePoolReceiver.sol:IncentivePoolReceiver",
    constructorArguments: [
      contractAddresses.ExtraIncentivePool,
      contractAddresses.IncentiveToken,
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
