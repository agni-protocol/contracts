import { ethers,network } from "hardhat";
import { abi } from "@agniswap/core/artifacts/contracts/AgniFactory.sol/AgniFactory.json";
const utils = require("../../common/utils");

let WMNT="";
let AGNI="";

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

   let coreContractAddresses = utils.getContractAddresses(
     networkName,`../core/deployments/${networkName}.json`
   );
   console.log("core contract addresses:", coreContractAddresses);

    let masterChefContractAddresses = utils.getContractAddresses(
      networkName,`../masterChef/deployments/${networkName}.json`
    );
    console.log("masterChef contract addresses:", masterChefContractAddresses);

   if (networkName == "mantleMainnet") {
     WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
     AGNI = "";
   } else {
     WMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
     AGNI = "0x113667C49c053230D3232AC7d74F471Dcd42f11E";
   }
   console.log("WMNT addresses:", WMNT);


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
  await utils.writeContractAddresses(networkName,contractAddresses);

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
