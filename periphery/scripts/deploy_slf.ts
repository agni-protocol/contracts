import { ethers } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";

async function main() {
  const [owner] = await ethers.getSigners();

  const SelfSufficientERC20 = await ethers.getContractFactory(
    "SelfSufficientERC20"
  );
  // const USDC = await SelfSufficientERC20.deploy();
  // await USDC.initlialize("MockUSDC", "USDC", 6);
  // console.log("USDC", USDC.address);
  // await USDC.mint(owner.address, BigNumber.from("10000000000000000000000000"));
  // await USDC.mint(
  //   "0xf172E28863C417AA71ac691A8bc02CdFc856daFA",
  //   BigNumber.from("10000000000000000000000000")
  // );

  const AGNI = await SelfSufficientERC20.deploy();
  await AGNI.initlialize("MockDOGE", "DOGE", 18);
  console.log("AGNI", AGNI.address);
  await AGNI.mint(owner.address, BigNumber.from("10000000000000000000000000"));
  await AGNI.mint(
    "0xcbe467AFe8Bb198a3924BAD8B509a3160647313a",
    BigNumber.from("10000000000000000000000000")
  );

  // const TickMath = await ethers.getContractFactory("ExternalTickMath");
  // const tickMath = await TickMath.deploy();
  // console.log("TickMath", tickMath.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
