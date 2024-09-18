import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

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
