const { parseUnits } = ethers.utils;
const { address } = require("../utils/helpers");

const medianOracleUpdatePrice = async ({
  wbtc,
  cvx,
  fundingCvx,
  fundingWbtc,
  eoaOracle,
  keeper,
  medianOracleWbtc,
  medianOracleCvx,
}) => {
  await medianOracleWbtc.addProvider(address(keeper));
  await medianOracleCvx.addProvider(address(keeper));

  // TODO: needs to handle this price more realisticly
  await medianOracleWbtc.connect(keeper).pushReport(5000 + 600);
  await medianOracleCvx.connect(keeper).pushReport(5000 + 600);

  await fundingWbtc.connect(keeper).updateCitadelPerAsset();
  await fundingCvx.connect(keeper).updateCitadelPerAsset();
};

module.exports = medianOracleUpdatePrice;
