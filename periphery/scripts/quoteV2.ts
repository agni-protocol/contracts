import { ethers,network } from "hardhat";
const utils = require("../../common/utils");
import { encodePath } from "../test/shared/path";

const agniAddress = "0x201eba5cc46d216ce6dc03f6a759e8e766e956ae";

enum FeeAmount {
  LOW = 500,
  MEDIUM = 2500,
  HIGH = 10000,
}

async function main() {
   const networkName = await network.name;
   console.log("Network name=", networkName);

    const [owner] = await ethers.getSigners();
    let contractAddresses = utils.getContractAddresses(networkName,"");
    console.log("contractAddresses:", contractAddresses);

    const QuoterV2 = await ethers.getContractAt(
      "QuoterV2",
      contractAddresses.QuoterV2
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
