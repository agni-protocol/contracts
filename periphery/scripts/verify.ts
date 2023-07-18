const hre = require("hardhat");
const utils = require("../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  let coreContractAddresses = utils.getContractAddresses(`../core/deployments/${process.env.NETWORK}.json`);
  console.log("core contract addresses:", coreContractAddresses);

  let WMNT = process.env.WMNT !== undefined ? process.env.WMNT : "";
  console.log("WMNT addresses:", WMNT);

  let contractAddresses = utils.getContractAddresses("");
  console.log("periphery contract addresses:", coreContractAddresses);

  await hre.run("verify:verify", {
    address: contractAddresses.SwapRouter,
    contract: "contracts/SwapRouter.sol:SwapRouter",
    constructorArguments: [coreContractAddresses.AgniPoolDeployer, coreContractAddresses.AgniFactory, WMNT],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.QuoterV2,
    contract: "contracts/lens/QuoterV2.sol:QuoterV2",
    constructorArguments: [coreContractAddresses.AgniPoolDeployer, coreContractAddresses.AgniFactory, WMNT],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.TickLens,
    contract: "contracts/lens/TickLens.sol:TickLens",
    constructorArguments: [],
  });

   await hre.run("verify:verify", {
     address: contractAddresses.NFTDescriptor,
     contract:
       "contracts/NFTDescriptor.sol:NFTDescriptor",
     constructorArguments: [],
   });

    await hre.run("verify:verify", {
      address: contractAddresses.NonfungibleTokenPositionDescriptor,
      contract:
        "contracts/NonfungibleTokenPositionDescriptorOffChain.sol:NonfungibleTokenPositionDescriptorOffChain",
      constructorArguments: [process.env.TOKEN_URI],
    });

     await hre.run("verify:verify", {
       address: contractAddresses.NonfungiblePositionManager,
       contract:
         "contracts/NonfungiblePositionManager.sol:NonfungiblePositionManager",
       constructorArguments: [
         coreContractAddresses.AgniPoolDeployer,
         coreContractAddresses.AgniFactory,
         WMNT,
         contractAddresses.NonfungibleTokenPositionDescriptor,
       ],
     });

      // await hre.run("verify:verify", {
      //   address: contractAddresses.AgniInterfaceMulticall,
      //   contract:
      //     "contracts/lens/AgniInterfaceMulticall.sol:AgniInterfaceMulticall",
      //   constructorArguments: [],
      // });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
