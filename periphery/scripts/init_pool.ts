import { ethers,network } from "hardhat";
const utils = require("../../common/utils");
const {encodePriceSqrt} = require("../test/shared/encodePriceSqrt");
const {formatSqrtRatioX96 } = require("../test/shared/formatSqrtRatioX96");

let wmntAddress = "";
const usdcAddress = "0x74a0E7118480bdfF5f812c7a879a41db09ac2c39"; // testnet
// const usdcAddress = "0x201eba5cc46d216ce6dc03f6a759e8e766e956ae"; // mainnet

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let coreContractAddresses = utils.getContractAddresses(
    networkName,
    `../core/deployments/${networkName}.json`
  );
  console.log("core contract addresses:", coreContractAddresses);

  let contractAddresses = utils.getContractAddresses(networkName, "");
  console.log("contractAddresses:", contractAddresses);
  wmntAddress = contractAddresses.WMNT;

  // Agni/WMNT = 2
  let price = encodePriceSqrt(2, 1); 
  console.log("sqrtPrice:", price);

  let priceStr = formatSqrtRatioX96(price);
  console.log("priceStr:", priceStr);

  const positionManager = await ethers.getContractAt(
    "NonfungiblePositionManager",
    contractAddresses.NonfungiblePositionManager
  );

  let token0 = wmntAddress < usdcAddress ? wmntAddress : usdcAddress;
  let token1 = usdcAddress > wmntAddress ? usdcAddress : wmntAddress;
  console.log("token0:", token0);
  console.log("token1:", token1);

  let initPoolTx = await positionManager.createAndInitializePoolIfNecessary(
    wmntAddress < usdcAddress ? wmntAddress : usdcAddress,
    usdcAddress > wmntAddress ? usdcAddress : wmntAddress,
    500,
    price
  );
  console.log("initPoolTx pool success:", initPoolTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
