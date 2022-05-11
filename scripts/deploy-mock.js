const hre = require("hardhat");

const deployWithMock = require("./actions/deployWithMock");

async function main() {
  await deployWithMock();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
