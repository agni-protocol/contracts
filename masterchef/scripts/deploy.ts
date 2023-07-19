import { ethers,network } from "hardhat";
const utils = require("../../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let peripheryContractAddresses = utils.getContractAddresses(networkName,`../periphery/deployments/${networkName}.json`);
  console.log("periphery contract addresses:", peripheryContractAddresses);

  let WMNT = process.env.WMNT !== undefined ? process.env.WMNT : "";
  console.log("WMNT addresses:", WMNT);

  let AGNI = process.env.AGNI !== undefined ? process.env.AGNI : "";
  console.log("AGNI addresses:", AGNI);

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
