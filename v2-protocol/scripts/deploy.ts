import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

const WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
const feeTo = "0xB4ebe166513C578e33A8373f04339508bC7E8Cfb";

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  const accounts = await ethers.getSigners();
  const deployerSigner = accounts[0].address;
  console.log("deployer address:%s", deployerSigner);

  const AgniFactory = await ethers.getContractFactory("AgniFactory");
  const agniFactory = await AgniFactory.deploy(deployerSigner);
  console.log("AgniFactory deployed to", agniFactory.address);

  let setFactoryFeeToTx = await agniFactory.setFeeTo(feeTo);
  console.log("AgniFactory setFeeTo tx:", setFactoryFeeToTx.hash);
  
  const AgniRouter = await ethers.getContractFactory("AgniRouter");
  const agniRouter = await AgniRouter.deploy(agniFactory.address, WMNT);
  console.log("AgniRouter deployed to", agniRouter.address);

  const  INIT_CODE_PAIR_HASH = await agniFactory.INIT_CODE_PAIR_HASH();

  let contractAddresses = {
    AgniFactory: agniFactory.address,
    AgniRouter: agniRouter.address,
    AgniFeeSetter: deployerSigner,
    AgniFeeTo: feeTo,
    WMNT: WMNT,
    INIT_CODE_PAIR_HASH: INIT_CODE_PAIR_HASH
  };
  await utils.writeContractAddresses(networkName,contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
