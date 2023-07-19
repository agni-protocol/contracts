const fs = require("fs");


function getContractAddresses(network, filename) {
  if (filename == "") {
    return JSON.parse(
      fs.readFileSync(`${process.cwd()}/deployments/${network}.json`).toString()
    );
  }

  return JSON.parse(fs.readFileSync(filename).toString());
}

function writeContractAddresses(network, contractAddresses) {
  fs.writeFileSync(
    `${process.cwd()}/deployments/${network}.json`,
    JSON.stringify(contractAddresses, null, 2) // Indent 2 spaces
  );
}

module.exports = {
  getContractAddresses,
  writeContractAddresses,
};