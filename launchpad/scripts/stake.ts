import { ethers,network } from "hardhat";
const utils = require("../../common/utils");
import { BigNumber } from "@ethersproject/bignumber";
import dotenv from "dotenv";
dotenv.config();


async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName,"");

  let AGNI = process.env.AGNI !== undefined ? process.env.AGNI : "";
  console.log("AGNI addresses:", AGNI);

  const [owner, keeper] = await ethers.getSigners();

  // score calc check
  const ScoreCalculator = await ethers.getContractFactory("ScoreCalculator");
  const scoreCalculator = await ScoreCalculator.attach(
    contractAddresses.ScoreCalculator.Proxy
  );

  let scoreMama = await scoreCalculator.agniToken();
  console.log("score agni token:", scoreMama);

  if (scoreMama == "0x0000000000000000000000000000000000000000"){
    let setAgniTokenTx = await scoreCalculator.setAgniToken(AGNI);
    console.log("setAgniTokenTx :", setAgniTokenTx.hash);
  }

  let score = await scoreCalculator.calculate(
    AGNI,
    BigNumber.from("1000000000000000000000")
  );
  console.log("score:", score);

  // stake
  const StakingPool = await ethers.getContractFactory("StakingPool");
  const stakingPool = await StakingPool.attach(contractAddresses.StakingPool);

  let scoreCalculatorAddress = await stakingPool.scoreCalculator();
  console.log("stakingPool scoreCalculatorAddress:", scoreCalculatorAddress);

  if (contractAddresses.ScoreCalculator.Proxy != scoreCalculatorAddress) {
    console.log("invalid scoreCalculatorAddress");
    return;
  }

  let isStakingToken = await stakingPool.isStakingToken(AGNI);
  console.log("isStakingToken:", isStakingToken);

  let tier = await stakingPool.getTierByScore(score);
  console.log("getTierByScore:", tier);

  // check staking token
  if (!isStakingToken) {
    let addTx = await stakingPool.addStakingToken(AGNI);
    console.log("addStakingToken:", addTx.hash);
  }

  // approve first
  const agni = await ethers.getContractAt("SelfSufficientERC20", AGNI);

  let balance = await agni.balanceOf(owner.address);
  console.log("balance:", balance.toString());

  let allownce = await agni.allowance(
    owner.address,
    contractAddresses.StakingPool
  );
  console.log("allownce:", allownce.toString());

  if (allownce.toString() == "0") {
    let approveTx = await agni.approve(
      contractAddresses.StakingPool,
      BigNumber.from("10000000000000000000000000000")
    );
    console.log("approveTx hash:", approveTx.hash);
  }

  //  do stake
  // let stakeTx = await stakingPool.stake(
  //   AGNI,
  //   BigNumber.from("1000000000000000000000")
  // );
  // console.log("stakeTx tx:", stakeTx.hash);

  // do unstake
  let unstakeTx = await stakingPool.unstake([0]);
  console.log("unstakeTx tx:", unstakeTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
