import { ethers, network } from "hardhat";
const Web3 = require("web3");
const utils = require("../../common/utils");

async function main() {
  const networkName = await network.name;
  console.log("Network name=", networkName);

  let contractAddresses = utils.getContractAddresses(networkName, "");
  console.log("contractAddresses:", contractAddresses);

  let pairs = await fetchPairs();

  for (let item in pairs.data.pools) {
    console.log("index: ", item, " pair: ", pairs.data.pools[item].id);
    if (parseInt(item) < 108) {
      continue;
    }

    let poolAddress = pairs.data.pools[item].id;

    const AgniPool = await ethers.getContractAt("AgniPool", poolAddress);
    // let fee = await AgniPool.fee();
    // console.log("fee:", fee);

    let token0 = await AgniPool.token0();
    let token0Obj = await ethers.getContractAt("ERC20", token0);
    // console.log("token0:", token0);
    const token0Decimals = await token0Obj.decimals();
    const token0Name = await token0Obj.symbol();

    let token1 = await AgniPool.token1();
    let token1Obj = await ethers.getContractAt("ERC20", token1);
    // console.log("token1:", token1);
    const token1Decimals = await token1Obj.decimals();
    const token1Name = await token1Obj.symbol();

    let pfee = await AgniPool.protocolFees();
    console.log(
      "token0: ",
      token0Name,
      "fee balance: ",
      ethers.utils.formatUnits(pfee.token0, token0Decimals)
    );
    console.log(
      "token1:",
      token1Name,
      "fee balance: ",
      ethers.utils.formatUnits(pfee.token1, token1Decimals)
    );

    // 0 fee
    if (pfee.token0.isZero() && pfee.token1.isZero()) {
      continue;
    }

    const AgniFactory = await ethers.getContractAt(
      "AgniFactory",
      contractAddresses.AgniFactory
    );

    let collectFee = await AgniFactory.collectProtocol(
      poolAddress,
      "0x753294CE825fFcdFC31E6676D66907D81a948668",
      pfee.token0,
      pfee.token1
    );
    console.log("collectFee success, tx:", collectFee.hash);
  }
}

async function fetchPairs() {
  var myHeaders = new Headers();
  myHeaders.append("Content-Type", "application/json");

  var graphql = JSON.stringify({
    query:
      "query b {\n  pools(first: 1000) {\n    id\n    token0 {\n      symbol\n    }\n    token1 {\n      symbol\n    }\n  }\n}",
    variables: {},
  });
  var requestOptions = {
    method: "POST",
    headers: myHeaders,
    body: graphql,
    redirect: "follow",
  };

  let response = await fetch(
    "https://agni.finance/graph/subgraphs/name/agni/exchange-v3",
    requestOptions
  );

  let data = "";
  if (response.ok) {
    data = await response.text();
  } else {
    console.log("Error HTTP: " + response.status);
  }
  return JSON.parse(data);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
