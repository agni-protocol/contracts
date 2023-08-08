import { ethers, network } from "hardhat";
const Web3 = require("web3");
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  const [owner] = await ethers.getSigners();

  let contractAddresses = utils.getContractAddresses(networkName, "");
  console.log("contractAddresses:", contractAddresses);

  let poolAddress = "0x3377bcB58a7eF2216371B7d0AB289D06dE3b373F";
  const AgniPool = await ethers.getContractAt("AgniPool", poolAddress);

  let fee = await AgniPool.fee();
  console.log("fee:", fee);

  let token0 = await AgniPool.token0();
  console.log("token0:", token0);

  let token1 = await AgniPool.token1();
  console.log("token1:", token1);

  let pfee = await AgniPool.protocolFees();
  console.log("token0 fee:", pfee.token0);
  console.log("token1 fee:", pfee.token1);
  return

  const AgniFactory = await ethers.getContractAt(
    "AgniFactory",
    contractAddresses.AgniFactory
  );

  let collectFee = await AgniFactory.collectProtocol(poolAddress, owner.address, pfee.token0,pfee.token1);
  console.log("collectFee success, tx:", collectFee.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
