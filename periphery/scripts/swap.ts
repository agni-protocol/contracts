import { ethers,network } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";
const utils = require("../common/utils");

const agniAddress = "0x74a0E7118480bdfF5f812c7a879a41db09ac2c39";
let wmntAddress = "";

async function main() {
   const networkName = await network.name;
   console.log("Network name=", networkName);

  const [owner] = await ethers.getSigners();
  let contractAddresses = utils.getContractAddresses(networkName,"");
  wmntAddress = contractAddresses.WMNT;

  const swapRouter = await ethers.getContractAt(
    "SwapRouter",
    contractAddresses.SwapRouter
  );

  const MNT = await ethers.getContractAt("WMNT", wmntAddress);
  let mammApproveTx = await MNT.approve(
    contractAddresses.SwapRouter,
    BigNumber.from("10000000000000000000000000000")
  );
  console.log("MNT approve tx:", mammApproveTx.hash);

  const AGNI = await ethers.getContractAt("SelfSufficientERC20", agniAddress);
  await AGNI.approve(
    contractAddresses.SwapRouter,
    BigNumber.from("10000000000000000000000000000")
  );
  console.log("approve success");

  await swapRouter.exactInputSingle({
    tokenIn: wmntAddress,
    tokenOut: agniAddress,
    fee: 100,
    recipient: owner.address,
    deadline: 999999999,
    amountIn: BigNumber.from("11000000000000000000"),
    amountOutMinimum: 0,
    sqrtPriceLimitX96: 0,
  });
  console.log("swap success");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
