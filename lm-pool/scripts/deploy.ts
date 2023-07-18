import { ethers } from "hardhat";
import { abi } from "@agniswap/core/artifacts/contracts/AgniFactory.sol/AgniFactory.json";
const utils = require("../common/utils");

import dotenv from "dotenv";
dotenv.config();

async function main() {
   let coreContractAddresses = utils.getContractAddresses(
     `../core/deployments/${process.env.NETWORK}.json`
   );
   console.log("core contract addresses:", coreContractAddresses);

    let masterChefContractAddresses = utils.getContractAddresses(
      `../masterChef/deployments/${process.env.NETWORK}.json`
    );
    console.log("masterChef contract addresses:", masterChefContractAddresses);

   let WMNT = process.env.WMNT !== undefined ? process.env.WMNT : "";
   console.log("WMNT addresses:", WMNT);

   let AGNI = process.env.AGNI !== undefined ? process.env.AGNI : "";
   console.log("AGNI addresses:", AGNI);

  const AgniLmPoolDeployer = await ethers.getContractFactory(
    "AgniLmPoolDeployer"
  );
  const agniLmPoolDeployer = await AgniLmPoolDeployer.deploy(
    masterChefContractAddresses.MasterChef
  );
  console.log("AgniLmPoolDeployer", agniLmPoolDeployer.address);

  let contractAddresses = {
    AgniLmPoolDeployer: agniLmPoolDeployer.address,
  };
  await utils.writeContractAddresses(contractAddresses);

  const [owner] = await ethers.getSigners();
  const agniFactory = new ethers.Contract(
    coreContractAddresses.AgniFactory,
    abi,
    owner
  );
  let tx = await agniFactory.setLmPoolDeployer(agniLmPoolDeployer.address);
  console.log("SetLmPoolDeployer success, tx: ", tx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
