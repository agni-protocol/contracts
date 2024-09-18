import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

let WMNT = "";
let AGNI = "";

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let peripheryContractAddresses = utils.getContractAddresses(networkName,`../periphery/deployments/${networkName}.json`);
  console.log("periphery contract addresses:", peripheryContractAddresses);

 if (networkName == "mantleMainnet") {
   WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
   AGNI = "";
 } else {
   WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
   AGNI = "0xd3b2241BfF9654195F814a15CbAc458C72Fa5084";
 }
 console.log("WMNT addresses:", WMNT);

  // deploy masterChef
  const MasterChef = await ethers.getContractFactory("MasterChef");
  const masterChef = await MasterChef.deploy(
    AGNI,
    peripheryContractAddresses.NonfungiblePositionManager,
    WMNT
  );
  console.log("masterChef deployed to:", masterChef.address);

  // deploy receiver
  const MasterChefV3Receiver = await ethers.getContractFactory("MasterChefV3Receiver");
  const masterChefV3Receiver = await MasterChefV3Receiver.deploy(
    masterChef.address,
    AGNI
  );
  console.log("masterChefV3Receiver deployed to:", masterChefV3Receiver.address);

  let contractAddresses = {
    MasterChef: masterChef.address,
    MasterChefV3Receiver: masterChefV3Receiver.address,
  };
  await utils.writeContractAddresses(networkName,contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
