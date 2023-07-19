import { ethers,upgrades,network } from "hardhat";
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

  let WMNT="";
  if (networkName == "mantleMainnet"){
    WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
  }else{
    WMNT = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
  }
  console.log("WMNT addresses:", WMNT);

  const Multicall = await ethers.getContractFactory("AgniInterfaceMulticall");
  const multicall = await Multicall.deploy();
  console.log("Multicall", multicall.address);

  const SwapRouter = await ethers.getContractFactory("SwapRouter");
  const swapRouter = await SwapRouter.deploy(
    coreContractAddresses.AgniPoolDeployer,
    coreContractAddresses.AgniFactory,
    WMNT
  );
  console.log("SwapRouter", swapRouter.address);

  const QuoterV2 = await ethers.getContractFactory("QuoterV2");
  const quoterV2 = await QuoterV2.deploy(coreContractAddresses.AgniPoolDeployer, coreContractAddresses.AgniFactory, WMNT);
  console.log("QuoterV2", quoterV2.address);

  const TickLens = await ethers.getContractFactory("TickLens");
  const tickLens = await TickLens.deploy();
  console.log("TickLens", tickLens.address);

  const NFTDescriptor = await ethers.getContractFactory("NFTDescriptor");
  const nftDescriptor = await NFTDescriptor.deploy();
  console.log("NFTDescriptor", nftDescriptor.address);

  const NonfungibleTokenPositionDescriptor = await ethers.getContractFactory(
    "NonfungibleTokenPositionDescriptorOffChain"
  );
  const nonfungibleTokenPositionDescriptor = await upgrades.deployProxy(
    NonfungibleTokenPositionDescriptor,
    [process.env.TOKEN_URI]
  );
  await nonfungibleTokenPositionDescriptor.deployed();
  console.log(
    "NonfungibleTokenPositionDescriptor deployed at",
    nonfungibleTokenPositionDescriptor.address
  );

  const NonfungiblePositionManager = await ethers.getContractFactory(
    "NonfungiblePositionManager"
  );
  const nonfungiblePositionManager = await NonfungiblePositionManager.deploy(
    coreContractAddresses.AgniPoolDeployer,
    coreContractAddresses.AgniFactory,
    WMNT,
    nonfungibleTokenPositionDescriptor.address
  );
  console.log("NonfungiblePositionManager", nonfungiblePositionManager.address);

  let contractAddresses = {
    WMNT: WMNT,
    SwapRouter: swapRouter.address,
    QuoterV2: quoterV2.address,
    TickLens: tickLens.address,
    NFTDescriptor: nftDescriptor.address,
    NonfungibleTokenPositionDescriptor:
      nonfungibleTokenPositionDescriptor.address,
    NonfungiblePositionManager: nonfungiblePositionManager.address,
    AgniInterfaceMulticall: multicall.address,
  };
  await utils.writeContractAddresses(networkName,contractAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
