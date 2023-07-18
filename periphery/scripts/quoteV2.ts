import { ethers } from "hardhat";
const utils = require("../common/utils");
import { encodePath } from "../test/shared/path";

// const wmntAddress = "0xEa12Be2389c2254bAaD383c6eD1fa1e15202b52A";
const agniAddress = "0x74a0E7118480bdfF5f812c7a879a41db09ac2c39";

enum FeeAmount {
  LOW = 500,
  MEDIUM = 2500,
  HIGH = 10000,
}

async function main() {
    const [owner] = await ethers.getSigners();
    let contractAddresses = utils.getContractAddresses("");
    console.log("contractAddresses:", contractAddresses);

    const QuoterV2 = await ethers.getContractAt(
      "QuoterV2",
      "0xb0a16B90D8a35AA859B058B869364A3758Ba4D14"
    );
    console.log("QuoterV2:", contractAddresses.QuoterV2);

    let wmntAddress = await QuoterV2.callStatic.WMNT();
    console.log("wmntAddress:", wmntAddress);

    let path = encodePath([wmntAddress, agniAddress], [FeeAmount.LOW]);
    console.log("path:", path);

   let res = await QuoterV2.callStatic.quoteExactInput(
     encodePath([wmntAddress, agniAddress], [FeeAmount.LOW]),
     "100000000000000000"
   );

    console.log(res);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
