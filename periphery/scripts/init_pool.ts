import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

let wmntAddress = "";
// const usdcAddress = "0x82A2eb46a64e4908bBC403854bc8AA699bF058E9"; // testnet
const usdcAddress = "0x201eba5cc46d216ce6dc03f6a759e8e766e956ae"; // mainnet

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

  let token0 = wmntAddress < usdcAddress ? wmntAddress : usdcAddress;
  let token1 = usdcAddress > wmntAddress ? usdcAddress : wmntAddress;
  console.log("token0:", token0);
  console.log("token1:", token1);
  return

  let initPoolTx = await positionManager.createAndInitializePoolIfNecessary(
    wmntAddress < usdcAddress ? wmntAddress : usdcAddress,
    usdcAddress > wmntAddress ? usdcAddress : wmntAddress,
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
