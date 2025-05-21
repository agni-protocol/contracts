const hre = require("hardhat");
const {network} = require("hardhat");
const utils = require("../../common/utils");


async function main() {
    const networkName = await network.name;
    console.log("Network name=", networkName);

    let contractAddresses = utils.getContractAddresses(networkName, "");

    await hre.run("verify:verify", {
        address: contractAddresses.AgniFactory,
        contract: "contracts/AgniFactory.sol:AgniFactory",
        constructorArguments: [contractAddresses.AgniFeeSetter],
    });

    await hre.run("verify:verify", {
        address: contractAddresses.AgniRouter,
        contract: "contracts/AgniRouter.sol:AgniRouter",
        constructorArguments: [
            contractAddresses.AgniFactory,
            contractAddresses.WMNT,
        ],
    });
    await hre.run("verify:verify", {
        address: "0xD14c2A2950eA3B7BAdD6bDDB18f7A7744Cd705Be",
        contract: "contracts/AgniPair.sol:AgniPair",
        constructorArguments: [],
    });
    await hre.run("verify:verify", {
        address: "0x43925FFfaDe90C48FBd12384D5F4d4DA9C359fc4",
        contract: "contracts/AgniPair.sol:AgniPair",
        constructorArguments: [],
    });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
