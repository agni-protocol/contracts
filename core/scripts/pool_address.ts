import { ethers, network } from "hardhat";
const utils = require("../../common/utils");
import PoolArtifact from "../artifacts/contracts/AgniPool.sol/AgniPool.json";

const token0 = "0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE";
const token1 = "0x78c1b0c915c4faa5fffa6cabf0219da63d7f4cb8";
const fee = 500;

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName,"");
  console.log("contractAddresses:", contractAddresses);

  const AgniFactory = await ethers.getContractAt(
    "AgniFactory",
    contractAddresses.AgniFactory
  );
  let poolAddress = await AgniFactory.getPool(token0, token1, fee);
  console.log("getPool:", poolAddress);

  const hash = ethers.utils.keccak256(PoolArtifact.bytecode);
  console.log(hash);

  // const AgniPool = await ethers.getContractAt(
  //   "AgniPool",
  //   "0xabb213151ee053180348d9423f7f8daf24f46f02"
  // );

  // let slot0 = await AgniPool.slot0();
  // console.log("slot0:", slot0);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
