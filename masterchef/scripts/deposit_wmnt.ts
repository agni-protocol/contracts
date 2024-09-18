import { ethers,network } from "hardhat";
const utils = require("../../common/utils");
const provider = new ethers.providers.JsonRpcProvider();
const fs = require("fs");
const abi = JSON.parse(fs.readFileSync("./abi/WMNT.json", "utf8"));

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName, "");

  const accounts = await hre.ethers.getSigners();
  const wmntContract = new ethers.Contract(
    contractAddresses.WMNT,
    abi,
    accounts[0]
  );

  let depositlTx = await wmntContract.deposit({ value: "100000000000000000000" });
  console.log("deposit tx: ", depositlTx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});