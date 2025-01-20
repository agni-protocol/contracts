const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);
  
  let contractAddresses = utils.getContractAddresses(networkName,"");

  // await hre.run("verify:verify", {
  //   address: contractAddresses.AgniPoolDeployer,
  //   contract: "contracts/AgniPoolDeployer.sol:AgniPoolDeployer",
  //   constructorArguments: [],
  // });
  //
  // await hre.run("verify:verify", {
  //   address: contractAddresses.AgniFactory,
  //   contract: "contracts/AgniFactory.sol:AgniFactory",
  //   constructorArguments: [contractAddresses.AgniPoolDeployer],
  // });
  //
  //  await hre.run("verify:verify", {
  //    address: contractAddresses.InitCodeHashAddress,
  //    contract: "contracts/test/OutputCodeHash.sol:OutputCodeHash",
  //    constructorArguments: [],
  //  });

  await hre.run("verify:verify", {
    address: '0x0d9e39d357337edde4a9bc12178da40256e2f533' ,
    contract: "contracts/AgniPool.sol:AgniPool",
    constructorArguments: [],
  });

  await hre.run("verify:verify", {
    address: '0xf9b5f2babdd388737be702dd732fb6b6bfe9dc20' ,
    contract: "contracts/AgniPool.sol:AgniPool",
    constructorArguments: [],
  });
  await hre.run("verify:verify", {
    address: '0x95d39c45668d59141dc5bcc940e6c191f1ebb98c' ,
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
