import { ethers } from "hardhat";
const c = require("../test/shared/computePoolAddress");

const token0 = "0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE";
const token1 = "0x78c1b0c915c4faa5fffa6cabf0219da63d7f4cb8";
const factory = "0x5d470E5E213EBa2DCd9E0AA1A9AE4ee2763d162d";
const deployer = "0xDc295A765DbB51b0948a86f835E7Ca37Ba4F3e03";
const fee = 500;


async function main() {
   let result = await c.computePoolAddress(deployer, [token0, token1], fee);
   console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
