const fs = require("fs");
import dotenv from "dotenv";
dotenv.config();

function getContractAddresses(filename) {
  if (filename==""){
    return JSON.parse(
      fs
        .readFileSync(
          `${process.cwd()}/deployments/${process.env.NETWORK}.json`
        )
        .toString()
    );
  }
  
   return JSON.parse(
     fs
       .readFileSync(filename)
       .toString()
   );
}

function writeContractAddresses(contractAddresses) {
  fs.writeFileSync(
    `${process.cwd()}/deployments/${process.env.NETWORK}.json`,
    JSON.stringify(contractAddresses, null, 2) // Indent 2 spaces
  );
}

module.exports = {
  getContractAddresses,
  writeContractAddresses,
};
