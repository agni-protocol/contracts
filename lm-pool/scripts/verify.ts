const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");

let WMNT="";
let AGNI="";


async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);
  if (networkName == "mantleMainnet") {
    WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    AGNI = "";
  } else {
    WMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
    AGNI = "0x113667C49c053230D3232AC7d74F471Dcd42f11E";
  }
  console.log("WMNT addresses:", WMNT);


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
