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
      WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
      AGNI = "0xd3b2241BfF9654195F814a15CbAc458C72Fa5084";
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
