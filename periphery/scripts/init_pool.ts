import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

let wmntAddress = "";
const usdtAddress = "0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE";

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName,"");
  console.log("contractAddresses:", contractAddresses);
  wmntAddress = contractAddresses.WMNT;

  const positionManager = await ethers.getContractAt(
    "NonfungiblePositionManager",
    contractAddresses.NonfungiblePositionManager
  );

  let initPoolTx = await positionManager.createAndInitializePoolIfNecessary(
    wmntAddress < usdtAddress ? wmntAddress : usdtAddress,
    usdtAddress > wmntAddress ? usdtAddress : wmntAddress,
    500,
    ethers.BigNumber.from("2").pow(96)
  );
  console.log("initPoolTx pool success:", initPoolTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
