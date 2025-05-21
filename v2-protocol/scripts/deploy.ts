import { ethers,network } from "hardhat";
const utils = require("../../common/utils");

let WMNT;
let feeTo;

async function main() {
  const networkName = await network.name;


  if (networkName == "mantleMainnet") {
    WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    feeTo = "0xD8A4c759bC19cC3E90e7151f0ccfb3120175ee27";
  } else {
    WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
    feeTo = "0xB4ebe166513C578e33A8373f04339508bC7E8Cfb";
  }

  console.log("Network name=", networkName);

  const accounts = await ethers.getSigners();
  const deployerSigner = accounts[0].address;
  console.log("deployer address:%s", deployerSigner);


  const AgniFactory = await ethers.getContractFactory("AgniFactory");
  const agniFactory = await AgniFactory.deploy(deployerSigner);
  console.log("AgniFactory deployed to", agniFactory.target);

  let setFactoryFeeToTx = await agniFactory.setFeeTo(feeTo);
  console.log("AgniFactory setFeeTo tx:", setFactoryFeeToTx.hash);
  
  const AgniRouter = await ethers.getContractFactory("AgniRouter");
  const agniRouter = await AgniRouter.deploy(agniFactory.target, WMNT);
  console.log("AgniRouter deployed to", agniRouter.target);

  const  INIT_CODE_PAIR_HASH = await agniFactory.INIT_CODE_PAIR_HASH();

  let contractAddresses = {
    AgniFactory: agniFactory.target,
    AgniRouter: agniRouter.target,
    AgniFeeSetter: deployerSigner,
    AgniFeeTo: feeTo,
    WMNT: WMNT,
    INIT_CODE_PAIR_HASH: INIT_CODE_PAIR_HASH
  };
  await utils.writeContractAddresses(networkName,contractAddresses);
}
async function main2() {
  const networkName = await network.name;


  if (networkName == "mantleMainnet") {
    WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    feeTo = "0xD8A4c759bC19cC3E90e7151f0ccfb3120175ee27";
  } else {
    WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
    feeTo = "0xB4ebe166513C578e33A8373f04339508bC7E8Cfb";
  }

  console.log("Network name=", networkName);

  const accounts = await ethers.getSigners();
  const deployerSigner = accounts[0].address;
  console.log("deployer address:%s", deployerSigner);

  let temp = utils.getContractAddresses(networkName,"");

  const AgniRouter = await ethers.getContractFactory("AgniRouter");
  const agniRouter = await AgniRouter.deploy(temp.AgniFactory, WMNT);
  console.log("AgniRouter deployed to", agniRouter.target);

  let contractAddresses = {
    ...temp,
    AgniRouter: agniRouter.target,
    AgniFeeSetter: deployerSigner,
    AgniFeeTo: feeTo,
    WMNT: WMNT,
  };
  await utils.writeContractAddresses(networkName,contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main2().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
