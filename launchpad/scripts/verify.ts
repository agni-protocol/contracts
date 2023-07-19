const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let peripheryContractAddresses = utils.getContractAddresses(
    networkName,
    `../periphery/deployments/${networkName}.json`
  );
  console.log("periphery contract addresses:", peripheryContractAddresses);

  let WMNT = process.env.WMNT !== undefined ? process.env.WMNT : "";
  console.log("WMNT addresses:", WMNT);

  let contractAddresses = utils.getContractAddresses(networkName,"");
  console.log(contractAddresses);

   const lockPeriod = 600;
   const tierScores = [
     50 * 1e8,
     100 * 1e8,
     500 * 1e8,
     1000 * 1e8,
     5000 * 1e8,
     10000 * 1e8,
   ];
    await hre.run("verify:verify", {
      address: contractAddresses.StakingPool,
      contract: "contracts/StakingPool.sol:StakingPool",
      constructorArguments: [
        WMNT,
        contractAddresses.ScoreCalculator.Proxy,
        lockPeriod,
        tierScores,
      ],
    });

    await hre.run("verify:verify", {
      address: contractAddresses.IdoPoolTemplate,
      contract: "contracts/IdoPool.sol:IdoPool",
      constructorArguments: [],
    });

    await hre.run("verify:verify", {
      address: contractAddresses.IdoPoolFactory,
      contract: "contracts/IdoPoolFactory.sol:IdoPoolFactory",
      constructorArguments: [contractAddresses.IdoPoolTemplate],
    });

    await hre.run("verify:verify", {
      address: contractAddresses.InsurancePool,
      contract: "contracts/InsurancePool.sol:InsurancePool",
      constructorArguments: [contractAddresses.IdoPoolFactory],
    });

    await hre.run("verify:verify", {
        address: contractAddresses.ScoreCalculator.Proxy,
        contract: "contracts/ScoreCalculator.sol:ScoreCalculator",
        constructorArguments: [],
    });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
