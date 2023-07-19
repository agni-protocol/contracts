import { ethers } from "hardhat";
const utils = require("../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  let contractAddresses = utils.getContractAddresses("");

  let WMNT = process.env.WMNT !== undefined ? process.env.WMNT : "";
  console.log("WMNT addresses:", WMNT);

  let AGNI = process.env.AGNI !== undefined ? process.env.AGNI : "";
  console.log("AGNI addresses:", AGNI);

  const [owner, keeper] = await ethers.getSigners();

  const StakingPool = await ethers.getContractFactory("StakingPool");
  const stakingPool = await StakingPool.attach(contractAddresses.StakingPool);

  const ScoreCalculator = await ethers.getContractFactory("ScoreCalculator");
  const scoreCalculator = await ScoreCalculator.attach(
    contractAddresses.ScoreCalculator.Proxy
  );

  // add agni
  let agniIsStakingToken = await stakingPool.isStakingToken(AGNI);
  if (!agniIsStakingToken){
      let addTx = await stakingPool.addStakingToken(AGNI);
      console.log("addStakingToken:", addTx.hash);
  }

  let scoreAgni = await scoreCalculator.agniToken();
  console.log("score agni token:", scoreAgni);

  if (scoreAgni == "0x0000000000000000000000000000000000000000") {
    let setAgniTokenTx = await scoreCalculator.setAgniToken(AGNI);
    console.log("setAgniTokenTx :", setAgniTokenTx.hash);
  }

  // add LP
  let agniMntFee100Lp = await scoreCalculator.isPoolSupported(AGNI, WMNT,100);
  console.log("scoreCalculator  isPoolSupported:", agniMntFee100Lp);
  if (!agniMntFee100Lp){
    let addAgniMntFee100LpTx = await scoreCalculator.supportPool(AGNI,WMNT,100);
    console.log("addAgniMntFee100LpTx:", addAgniMntFee100LpTx.hash);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
