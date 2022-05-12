const hre = require("hardhat");
const ethers = hre.ethers;
const deployLocal = require("./actions/deployLocal");

async function main() {
  await deployLocal();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
