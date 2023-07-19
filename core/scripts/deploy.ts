import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  const AgniPoolDeployer = await ethers.getContractFactory(
    "AgniPoolDeployer"
  );
  const agniPoolDeployer = await AgniPoolDeployer.deploy();
  console.log("AgniPoolDeployer", agniPoolDeployer.address);
  
  const AgniFactory = await ethers.getContractFactory("AgniFactory");
  const agniFactory = await AgniFactory.deploy(agniPoolDeployer.address);
  console.log("AgniFactory", agniFactory.address);
 
  let setFactoryAddressTx = await agniPoolDeployer.setFactoryAddress(agniFactory.address);
  console.log(
    "agniPoolDeployer setFactoryAddress tx:",
    setFactoryAddressTx.hash
  );

  const OutputCodeHash = await ethers.getContractFactory("OutputCodeHash");
  const outputCodeHash = await OutputCodeHash.deploy();
  console.log("OutputCodeHash", outputCodeHash.address);

  const hash = await outputCodeHash.getInitCodeHash();
  console.log("hash: ", hash);

  let contractAddresses = {
    AgniPoolDeployer: agniPoolDeployer.address,
    AgniFactory: agniFactory.address,
    InitCodeHashAddress: outputCodeHash.address,
    InitCodeHash: hash,
  };
  await utils.writeContractAddresses(networkName,contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
