const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");
import "@nomiclabs/hardhat-etherscan";


async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);
  
  let contractAddresses = utils.getContractAddresses(networkName,"");

  await hre.run("verify:verify", {
    address: contractAddresses.AgniFactory,
    contract: "contracts/AgniFactory.sol:AgniFactory",
    constructorArguments: [contractAddresses.AgniFeeSetter],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.AgniRouter,
    contract: "contracts/AgniRouter.sol:AgniRouter",
    constructorArguments: [
      contractAddresses.AgniFactory,
      contractAddresses.WMNT,
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
