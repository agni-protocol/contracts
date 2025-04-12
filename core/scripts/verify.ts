const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);
  
  let contractAddresses = utils.getContractAddresses(networkName,"");

  await hre.run("verify:verify", {
    address: contractAddresses.AgniPoolDeployer,
    contract: "contracts/AgniPoolDeployer.sol:AgniPoolDeployer",
    constructorArguments: [],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.AgniFactory,
    contract: "contracts/AgniFactory.sol:AgniFactory",
    constructorArguments: [contractAddresses.AgniPoolDeployer],
  });

   await hre.run("verify:verify", {
     address: contractAddresses.InitCodeHashAddress,
     contract: "contracts/test/OutputCodeHash.sol:OutputCodeHash",
     constructorArguments: [],
   });

  await hre.run("verify:verify", {
    address: '0xeAfc4D6d4c3391Cd4Fc10c85D2f5f972d58C0dD5' ,
    contract: "contracts/AgniPool.sol:AgniPool",
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
