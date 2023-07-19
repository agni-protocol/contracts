import { ethers,network } from "hardhat";
import { BigNumber, BigNumberish } from "@ethersproject/bignumber";
const utils = require("../../common/utils");

const wmntAddress = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
const usdcAddress = "0x82A2eb46a64e4908bBC403854bc8AA699bF058E9";

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  const [owner] = await ethers.getSigners();
  let contractAddresses = utils.getContractAddresses(networkName,"");
  console.log("contractAddresses:", contractAddresses);

  const MNT = await ethers.getContractAt("WMNT", wmntAddress);
  let mammApproveTx = await MNT.approve(
    contractAddresses.NonfungiblePositionManager,
    BigNumber.from("10000000000000000000000000000")
  );
  console.log("MNT approve tx:", mammApproveTx.hash);

  const USDC = await ethers.getContractAt("SelfSufficientERC20", usdcAddress);
  let usdcApproveTx = await USDC.approve(
    contractAddresses.NonfungiblePositionManager,
    BigNumber.from("10000000000000000000000000000")
  );
  console.log("usdc approve tx:", usdcApproveTx.hash);

  const positionManager = await ethers.getContractAt(
    "NonfungiblePositionManager",
    contractAddresses.NonfungiblePositionManager
  );

  let mintTx = await positionManager.mint({
    token0: wmntAddress,
    token1: usdcAddress,
    fee: 500,
    tickLower: -100,
    tickUpper: 100,
    amount0Desired: "100000000000000000",
    amount1Desired: "1000000",
    amount0Min: ethers.constants.Zero,
    amount1Min: ethers.constants.Zero,
    recipient: owner.address,
    deadline: 9999999999,
  });
  console.log("mint success:", mintTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
