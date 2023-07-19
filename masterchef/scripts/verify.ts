const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let peripheryContractAddresses = utils.getContractAddresses(
    networkName,`../periphery/deployments/${networkName}.json`
  );
  console.log("periphery contract addresses:", peripheryContractAddresses);

  let WMNT = "";
  let AGNI = "";

 if (networkName == "mantleMainnet") {
   WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
   AGNI = "";
 } else {
   WMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
   AGNI = "0x113667C49c053230D3232AC7d74F471Dcd42f11E";
 }
 console.log("WMNT addresses:", WMNT);
 console.log("AGNI addresses:", AGNI);

  let contractAddresses = utils.getContractAddresses(networkName,"");

  await hre.run("verify:verify", {
    address: contractAddresses.MasterChef,
    contract: "contracts/MasterChef.sol:MasterChef",
    constructorArguments: [
      AGNI,
      peripheryContractAddresses.NonfungiblePositionManager,
      WMNT,
    ],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.MasterChefV3Receiver,
    contract:
      "contracts/receiver/MasterChefV3Receiver.sol:MasterChefV3Receiver",
    constructorArguments: [contractAddresses.MasterChef, AGNI],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
