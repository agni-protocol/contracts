const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../common/utils");

async function main() {
   const networkName = await network.name;
   console.log("Network name=", networkName);

    let WMNT = "";
    if (networkName == "mantleMainnet") {
      WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    } else {
      WMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
    }
    console.log("WMNT addresses:", WMNT);

  let coreContractAddresses = utils.getContractAddresses(
    networkName,
    `../core/deployments/${networkName}.json`
  );
  console.log("core contract addresses:", coreContractAddresses);

  let contractAddresses = utils.getContractAddresses(networkName,"");
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
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
