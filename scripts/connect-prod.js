const hre = require("hardhat");
const ethers = hre.ethers;
const connectProd = require("./actions/connectProd");

async function main() {
  await connectProd();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
