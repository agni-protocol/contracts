const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");
import dotenv from "dotenv";
dotenv.config();


async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName,"");

   let masterChefContractAddresses = utils.getContractAddresses(
     networkName,`../masterChef/deployments/${process.env.NETWORK}.json`
   );
   console.log("masterChef contract addresses:", masterChefContractAddresses);

  await hre.run("verify:verify", {
    address: contractAddresses.AgniLmPoolDeployer,
    contract: "contracts/AgniLmPoolDeployer.sol:AgniLmPoolDeployer",
    constructorArguments: [masterChefContractAddresses.MasterChef],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
