const hre = require("hardhat");
const ethers = hre.ethers;
const { address } = require("../utils/helpers");

const initializeFundingRegistry = async ({
  fundingRegistry,
  tokenIns,
  deployer,
  MedianOracle,
  fundingImplementation,
  Funding,
  gac,
  citadel,
  xCitadel,
  treasuryVault,
  governance,
}) => {
  const assetCap = ethers.constants.MaxUint256;

  const initFunds = tokenIns.map((tk) => ({ asset: tk.address, assetCap }));

  const deployMedianOracle = async (i = 0) => {
    const currentFund = initFunds[i];
    if (!currentFund) return;

    const medianOracle = await MedianOracle.connect(deployer).deploy(
      10000,
      0,
      1
    );

    initFunds[i].citadelPerAssetOracle = medianOracle;

    return await deployMedianOracle(i + 1);
  };

  await deployMedianOracle();

  const formatInitFund = (iF) => [
    iF.asset,
    iF.citadelPerAssetOracle.address,
    iF.assetCap,
  ];

  const proxyAdminAddress = "0x8074Db4de0018b2E9E6866ea02c1eb608F751cCB";

  await fundingRegistry
    .connect(governance)
    .initialize(
      address(fundingImplementation),
      Funding.interface.getSighash("initialize"),
      proxyAdminAddress,
      address(gac),
      address(citadel),
      address(xCitadel),
      address(treasuryVault),
      initFunds.map(formatInitFund)
    );

  const fundingsAddresses = (await fundingRegistry.getAllFundingsData())
    .map(({ fundingAddress, asset }) => ({
      fundingAddress,
      asset,
    }))
    .map((fD) => {
      const properTokenIn = tokenIns.find(
        (tI) => tI.address.toLowerCase() === fD.asset.toLowerCase()
      );
      return {
        ...fD,
        ...properTokenIn,
      };
    });

  fundingsAddresses.forEach((fA) => {
    console.log(`${fA.name} funding address is: ${fA.fundingAddress}`);
  });

  return { fundingRegistry, proxyAdminAddress, initFunds };
};

module.exports = initializeFundingRegistry;
