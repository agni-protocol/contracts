import hre, {ethers, network} from "hardhat";

const utils = require("../../common/utils");


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


    const SmartRouterHelper = await ethers.getContractFactory('SmartRouterHelper')
    const smartRouterHelper = await SmartRouterHelper.deploy()
    console.log('SmartRouterHelper deployed to:', smartRouterHelper.address)


    const MixedRouteQuoterV1Factory = await ethers.getContractFactory("MixedRouteQuoterV1", {
        libraries: {
            SmartRouterHelper: smartRouterHelper.address,
        },
    });
    const mixedRouteQuoterV1 = await MixedRouteQuoterV1Factory.deploy(
        coreContractAddresses.AgniPoolDeployer,
        coreContractAddresses.AgniFactory,
        v2CoreContractAddresses.AgniFactory,
        WMNT
    );
    console.log("mixedRouteQuoterV1", mixedRouteQuoterV1.address);

    const SmartRouter = await ethers.getContractFactory('SmartRouter', {
        libraries: {
            SmartRouterHelper: smartRouterHelper.address,
        },
    })
    const smartRouter = await SmartRouter.deploy(
        v2CoreContractAddresses.AgniFactory,
        coreContractAddresses.AgniPoolDeployer,
        coreContractAddresses.AgniFactory,
        WMNT,
    )
    console.log('SmartRouterHelper deployed to:', smartRouter.address)

    {
        let contractAddresses = utils.getContractAddresses(networkName,"");
        utils.writeContractAddresses(
            networkName,
            {
                ...contractAddresses,
                mixedRouteQuoterV1:mixedRouteQuoterV1.address,
                smartRouterHelper:smartRouterHelper.address,
                smartRouter:smartRouter.address,
            }
        )
    }

    {
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
    {
        let contractAddresses = utils.getContractAddresses(networkName,"");
        await hre.run("verify:verify", {
            address: contractAddresses.smartRouter,
            contract: "contracts/SmartRouter.sol:SmartRouter",
            constructorArguments: [
                v2CoreContractAddresses.AgniFactory,
                coreContractAddresses.AgniPoolDeployer,
                coreContractAddresses.AgniFactory,
                WMNT,
            ],
        });
    }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
