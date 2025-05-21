import {ethers, network} from "hardhat";

const utils = require("../../common/utils");

let WMNT;
let USDT;
let USDC;
let feeTo;

async function main() {
    const networkName = network.name;

    console.log("Network name=", networkName);

    if (networkName == "mantleMainnet") {
        WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
        USDT = "0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE"
        USDC = "0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9"
        feeTo = "0xD8A4c759bC19cC3E90e7151f0ccfb3120175ee27";
    } else {
        WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
        USDT = "0xcc4ac915857532ada58d69493554c6d869932fe6"
        USDC = "0xcc4ac915857532ada58d69493554c6d869932fe6"
        feeTo = "0xB4ebe166513C578e33A8373f04339508bC7E8Cfb";
    }



    const accounts = await ethers.getSigners();
    const deployerSigner = accounts[0].address;
    console.log("deployer address:%s", deployerSigner);

    let contractAddresses = await utils.getContractAddresses(networkName, '');


    const AgniRouter = await ethers.getContractAt(
        "AgniRouter",
        contractAddresses.AgniRouter
    );
    // {
    //     const IERC20 = await ethers.getContractAt(
    //         "AgniERC20",
    //         USDT
    //     );
    //
    //     await IERC20.approve(
    //         contractAddresses.AgniRouter,
    //         "10000000000000000000000000000"
    //     )
    //
    //     await AgniRouter.addLiquidityETH(
    //         USDT,
    //         "100000000",
    //         "0",
    //         "0",
    //         feeTo,
    //         "134000000000000000000"
    //         , {
    //             value: "134000000000000000000"
    //         })
    //
    // }


    {
        const IERC20 = await ethers.getContractAt(
            "AgniERC20",
            USDC
        );

        await IERC20.approve(
            contractAddresses.AgniRouter,
            "10000000000000000000000000000"
        )

        await AgniRouter.addLiquidityETH(
            USDC,
            "100000000",
            "0",
            "0",
            feeTo,
            "134000000000000000000"
            , {
                value: "134000000000000000000"
            })
    }
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
