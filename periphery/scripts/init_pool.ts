import { ethers } from "hardhat";
const utils = require("../common/utils");

const wmntAddress = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
const usdtAddress = "0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE";

async function main() {
  let contractAddresses = utils.getContractAddresses("");
  console.log("contractAddresses:", contractAddresses);

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
