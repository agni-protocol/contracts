const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let coreContractAddresses = utils.getContractAddresses(
    networkName,
    `../core/deployments/${networkName}.json`
  );
  console.log("core contract addresses:", coreContractAddresses);

  let contractAddresses = utils.getContractAddresses(networkName, "");
  console.log("periphery contract addresses:", contractAddresses);

  let WMNT = contractAddresses.WMNT;

  await hre.run("verify:verify", {
    address: contractAddresses.Quoter,
    contract: "contracts/lens/Quoter.sol:Quoter",
    constructorArguments: [coreContractAddresses.AgniPoolDeployer, coreContractAddresses.AgniFactory, WMNT],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.QuoterV2,
    contract: "contracts/lens/QuoterV2.sol:QuoterV2",
    constructorArguments: [coreContractAddresses.AgniPoolDeployer, coreContractAddresses.AgniFactory, WMNT],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.SwapRouter,
    contract: "contracts/SwapRouter.sol:SwapRouter",
    constructorArguments: [
      coreContractAddresses.AgniPoolDeployer,
      coreContractAddresses.AgniFactory,
      WMNT,
    ],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.TickLens,
    contract: "contracts/lens/TickLens.sol:TickLens",
    constructorArguments: [],
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

  await hre.run("verify:verify", {
    address: contractAddresses.NonfungibleTokenPositionDescriptor,
    contract:
      "contracts/NonfungibleTokenPositionDescriptorOffChain.sol:NonfungibleTokenPositionDescriptorOffChain",
    constructorArguments: [],
  });

  await hre.run("verify:verify", {
    address: contractAddresses.NFTDescriptor,
    contract:
      "contracts/libraries/NFTDescriptor.sol:NFTDescriptor",
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
