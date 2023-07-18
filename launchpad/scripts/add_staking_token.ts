import { ethers } from "hardhat";
const utils = require("../common/utils");
const fs = require("fs");

const agniAddress = "0x74a0E7118480bdfF5f812c7a879a41db09ac2c39";
const wMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";

async function main() {
  let contractAddresses = utils.getContractAddresses("");

  const [owner, keeper] = await ethers.getSigners();

  const StakingPool = await ethers.getContractFactory("StakingPool");
  const stakingPool = await StakingPool.attach(contractAddresses.StakingPool);

  const ScoreCalculator = await ethers.getContractFactory("ScoreCalculator");
  const scoreCalculator = await ScoreCalculator.attach(
    contractAddresses.ScoreCalculator.Proxy
  );


  // add agni
  let agniIsStakingToken = await stakingPool.isStakingToken(agniAddress);
  if (!agniIsStakingToken){
      let addTx = await stakingPool.addStakingToken(agniAddress);
      console.log("addStakingToken:", addTx.hash);
  }

  let scoreMama = await scoreCalculator.agniToken();
  console.log("score agni token:", scoreMama);

  if (scoreMama == "0x0000000000000000000000000000000000000000") {
    let setAgniTokenTx = await scoreCalculator.setAgniToken(agniAddress);
    console.log("setAgniTokenTx :", setAgniTokenTx.hash);
  }

  // add LP
  let agniMntFee100Lp = await scoreCalculator.isPoolSupported(agniAddress, wMNT,100);
  console.log("scoreCalculator  isPoolSupported:", agniMntFee100Lp);
  if (!agniMntFee100Lp){
    let addMamaMntFee100LpTx = await scoreCalculator.supportPool(agniAddress,wMNT,100);
    console.log("addMamaMntFee100LpTx:", addMamaMntFee100LpTx.hash);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
