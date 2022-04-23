const fs = require("fs");
const path = require("path");
const hre = require("hardhat");
const ethers = hre.ethers;

async function main(r) {
  const networkName = hre.network.name;

  const signers = await ethers.getSigners();

  const Funding = await ethers.getContractFactory("Funding");

  /// === Variable Setup
  const governance = signers[12];

  const scriptsDirectory = path.join(__dirname, "..", "scripts-data");

  const deployData = JSON.parse(
    fs.readFileSync(
      path.join(scriptsDirectory, `${networkName}-mock-funding-addresses.json`),
      "utf8"
    )
  );

  const fundingWbtc = Funding.attach(deployData.fundingWbtc);

  const fundingCvx = Funding.attach(deployData.fundingCvx);

  console.log(await fundingWbtc.citadelPriceInAsset());


  console.log(await fundingWbtc.citadelPriceInAsset());

  await fundingWbtc.connect(governance).setCitadelAssetPriceBounds(5000, 200000);

  console.log(await fundingWbtc.minCitadelPriceInAsset());
  console.log(await fundingWbtc.maxCitadelPriceInAsset());

  await fundingWbtc["updateCitadelPriceInAsset(uint256)"](10000);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
