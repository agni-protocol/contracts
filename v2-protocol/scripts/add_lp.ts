import {ethers, network} from "hardhat";

const utils = require("../../common/utils");

let WMNT;

async function main() {
    const networkName = network.name;

    console.log("Network name=", networkName);

    if (networkName == "mantleMainnet") {
        WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    } else {
        WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
    }

    const accounts = await ethers.getSigners();
    const deployerSigner = accounts[0].address;
    console.log("deployer address:%s", deployerSigner);

    let contractAddresses = await utils.getContractAddresses(networkName, '');

    const USDT = "0xcc4ac915857532ada58d69493554c6d869932fe6"

    const AgniRouter = await ethers.getContractAt(
        "AgniRouter",
        contractAddresses.AgniRouter
    );
    const IERC20 = await ethers.getContractAt(
        "AgniERC20",
        USDT
    );

    // await IERC20.approve(
    //     contractAddresses.AgniRouter,
    //     "10000000000000000000000000000"
    // )

    await AgniRouter.addLiquidityETH(
        USDT,
        "1000000000000",
        "0",
        "0",
        deployerSigner,
        "1000000000000000000"
        , {
            value: "100000000000000000000"
        })
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
