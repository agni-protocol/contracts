import { ethers,network } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";
const utils = require("../../common/utils");
import dotenv from "dotenv";
dotenv.config();

const raiseToken = "0x82A2eb46a64e4908bBC403854bc8AA699bF058E9";      // USDC
// const sellingToken = "0x74a0E7118480bdfF5f812c7a879a41db09ac2c39";      // AGNI
let sellingToken;
let WMNT;
let AGNI;

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName,"");

  if (networkName == "mantleMainnet") {
    WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    AGNI = "";
  } else {
    WMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
    AGNI = "0x113667C49c053230D3232AC7d74F471Dcd42f11E";
  }
  console.log("WMNT addresses:", WMNT);
  sellingToken = AGNI;

  const [owner, keeper] = await ethers.getSigners();

  const IdoPoolFactory = await ethers.getContractFactory("IdoPoolFactory");
  const idoPoolFactory = await IdoPoolFactory.attach(
    contractAddresses.IdoPoolFactory
  );

  let idoFactoryOwner = await idoPoolFactory.owner();
  console.log("idoPoolFactory owner:", idoFactoryOwner);

  // check keeper
  let idoFactoryKeeper = await idoPoolFactory.keeper();
  console.log("idoPoolFactory keeper:", idoFactoryKeeper);

  if (idoFactoryKeeper != keeper.address) {
    let updateKeeperTx = await idoPoolFactory
      .connect(owner)
      .updateKeeper(keeper.address);
    console.log("idoPoolFactory update keeper tx:", updateKeeperTx.hash);
  }

  // check raising token
  let isRaisingTokenResult = await idoPoolFactory.isRaisingToken(raiseToken);
  console.log("idoPoolFactory isRaisingToken:", isRaisingTokenResult);
  if (!isRaisingTokenResult) {
    let addRaisingTokenTx = await idoPoolFactory
      .connect(owner)
      .addRaisingToken(raiseToken);
    console.log("idoPoolFactory addRaisingToken tx:", addRaisingTokenTx.hash);
  }

  // check platformTreasury
  let platformTreasury = await idoPoolFactory.platformTreasury();
  console.log("idoPoolFactory platformTreasury:", platformTreasury);
  if (platformTreasury == "0x0000000000000000000000000000000000000000") {
    let updatePlatformTreasuryTx = await idoPoolFactory
      .connect(owner)
      .updatePlatformTreasury(idoFactoryOwner);
    console.log(
      "idoPoolFactory updatePlatformTreasury tx:",
      updatePlatformTreasuryTx.hash
    );
  }

  // check platformCommissionFeeRate
  let platformCommissionFeeRate =
    await idoPoolFactory.platformCommissionFeeRate();
  console.log(
    "idoPoolFactory platformCommissionFeeRate:",
    platformCommissionFeeRate
  );
  if (platformCommissionFeeRate <= 0) {
    let updatePlatformCommissionFeeRatelTx = await idoPoolFactory
      .connect(owner)
      .updatePlatformCommissionFeeRate(10);
    console.log(
      "idoPoolFactory updatePlatformCommissionFeeRatel tx:",
      updatePlatformCommissionFeeRatelTx.hash
    );
  }

  // check insurancePool
  let insurancePool = await idoPoolFactory.insurancePool();
  console.log("idoPoolFactory insurancePool:", insurancePool);
  if (insurancePool == "0x0000000000000000000000000000000000000000") {
    let setInsurancePoolTx = await idoPoolFactory
      .connect(owner)
      .setInsurancePool(contractAddresses.InsurancePool, 15);
    console.log("idoPoolFactory setInsurancePool tx:", setInsurancePoolTx.hash);
  }

  // check stakingPool
  let stakingPool = await idoPoolFactory.stakingPool();
  console.log("idoPoolFactory stakingPool:", stakingPool);
  if (stakingPool == "0x0000000000000000000000000000000000000000") {
    let setstakingPoolTx = await idoPoolFactory
      .connect(owner)
      .updateStakingPool(contractAddresses.StakingPool);
    console.log("idoPoolFactory updateStakingPool tx:", setstakingPoolTx.hash);
  }

  let now = Date.parse(new Date().toString()) / 1000 + 3600 * 24;
  console.log("now:", now);

  let pool = await idoPoolFactory.connect(keeper).createIdoPool({
    fundraiser: idoFactoryOwner,
    raisingToken: raiseToken,
    sellingToken: sellingToken,
    totalSupply: BigNumber.from("10000000000000000000000"), // 10000个agni
    presalePrice: BigNumber.from("500000"), // 0.5U per agni
    publicSalePrice: BigNumber.from("1000000"), // 1U per agni
    presaleAndEnrollStartTime: BigNumber.from(now), // 预售开始时间
    presaleAndEnrollPeriod: BigNumber.from(7200), // 2个小时
    publicSaleDepositStartTime: BigNumber.from(now + 7200 + 1), // 公售开始时间
    publicSaleDepositPeriod: BigNumber.from(3600 * 24), // 公售持续1天
    claimStartTime: BigNumber.from(now + 7200 + 3600 * 24 + 100), // claim开始时间
    lockPeriod: BigNumber.from(3600 * 24 * 7), // 锁定7天
    tgeUnlockRatio: 50, // 初始解锁比例 50%
  });
  console.log("ido pool deploy tx:", pool.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
