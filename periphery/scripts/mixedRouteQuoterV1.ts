import hre, {ethers, network} from "hardhat";

const utils = require("../../common/utils");
import {encodePath} from "../test/shared/path";

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




    let coreContractAddresses = utils.getContractAddresses(
        networkName,
        `../core/deployments/${networkName}.json`
    );
    let v2CoreContractAddresses = utils.getContractAddresses(
        networkName,
        `../v2-protocol/deployments/${networkName}.json`
    );

    let WMNT = "";
    if (networkName == "mantleMainnet") {
        WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    } else {
        WMNT = "0x67A1f4A939b477A6b7c5BF94D97E45dE87E608eF";
    }
    console.log("WMNT addresses:", WMNT);


    // const SmartRouterHelper = await ethers.getContractFactory('SmartRouterHelper')
    // const smartRouterHelper = await SmartRouterHelper.deploy()
    // console.log('SmartRouterHelper deployed to:', smartRouterHelper.address)
    //
    //
    // const MixedRouteQuoterV1Factory = await ethers.getContractFactory("MixedRouteQuoterV1", {
    //     libraries: {
    //         SmartRouterHelper: smartRouterHelper.address,
    //     },
    // });
    // const mixedRouteQuoterV1 = await MixedRouteQuoterV1Factory.deploy(
    //     coreContractAddresses.AgniPoolDeployer,
    //     coreContractAddresses.AgniFactory,
    //     v2CoreContractAddresses.AgniFactory,
    //     WMNT
    // );
    // console.log("mixedRouteQuoterV1", mixedRouteQuoterV1.address);


    // let contractAddresses = utils.getContractAddresses(networkName,"");

    // utils.writeContractAddresses(
    //     networkName,
    //     {
    //         ...contractAddresses,
    //         mixedRouteQuoterV1:mixedRouteQuoterV1.address,
    //         smartRouterHelper:smartRouterHelper.address,
    //     }
    // )

    let contractAddresses = utils.getContractAddresses(networkName,"");
    await hre.run("verify:verify", {
        address: contractAddresses.mixedRouteQuoterV1,
        contract: "contracts/lens/MixedRouteQuoterV1.sol:MixedRouteQuoterV1",
        constructorArguments: [
            coreContractAddresses.AgniPoolDeployer,
            coreContractAddresses.AgniFactory,
            v2CoreContractAddresses.AgniFactory,
            WMNT
        ],
    });


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
