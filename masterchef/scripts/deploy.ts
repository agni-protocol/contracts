import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

let WMNT = "";
let AGNI = "";
let incentiveToken = "0x82a2eb46a64e4908bbc403854bc8aa699bf058e9"; //USDC

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let peripheryContractAddresses = utils.getContractAddresses(
    networkName,
    `../periphery/deployments/${networkName}.json`
  );
  console.log("periphery contract addresses:", peripheryContractAddresses);

  if (networkName == "mantleMainnet") {
    WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    AGNI = "";
  } else {
    WMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
    //  AGNI = "0x113667C49c053230D3232AC7d74F471Dcd42f11E";
    AGNI = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
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
  const MasterChefV3Receiver = await ethers.getContractFactory(
    "MasterChefV3Receiver"
  );
  const masterChefV3Receiver = await MasterChefV3Receiver.deploy(
    masterChef.address,
    AGNI
  );
  console.log(
    "masterChefV3Receiver deployed to:",
    masterChefV3Receiver.address
  );

  // deploy extra incentive pool
  const ExtraIncentivePool = await ethers.getContractFactory(
    "ExtraIncentivePool"
  );
  const extraIncentivePool = await ExtraIncentivePool.deploy(
    incentiveToken,
    masterChef.address
  );
  console.log("extraIncentivePool deployed to:", extraIncentivePool.address);

  // deploy incentive receiver
  const IncentivePoolReceiver = await ethers.getContractFactory(
    "IncentivePoolReceiver"
  );
  const incentivePoolReceiver = await IncentivePoolReceiver.deploy(
    extraIncentivePool.address,
    incentiveToken
  );
  console.log(
    "incentivePoolReceiver deployed to:",
    incentivePoolReceiver.address
  );

  let contractAddresses = {
    MasterChef: masterChef.address,
    MasterChefV3Receiver: masterChefV3Receiver.address,
    ExtraIncentivePool: extraIncentivePool.address,
    IncentivePoolReceiver: incentivePoolReceiver.address,
  };
  await utils.writeContractAddresses(networkName, contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
