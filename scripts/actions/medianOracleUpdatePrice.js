const { parseUnits } = ethers.utils;
const { address } = require("../utils/helpers");
const { getTokensPrices } = require("../utils/getTokensPrice");

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

  const tokens = [
    "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b",
  ];

  const tokensPrices = await getTokensPrices(tokens);

  const targetPrice = 21;

  // TODO: needs to handle this price more realisticly
  /// I'm not
  await medianOracleWbtc
    .connect(keeper)
    .pushReport(
      parseUnits(String(tokensPrices[tokens[0]].usd / targetPrice), 18)
    );
  await medianOracleCvx
    .connect(keeper)
    .pushReport(
      parseUnits(String(tokensPrices[tokens[1]].usd / targetPrice), 18)
    );

  await fundingWbtc.connect(keeper).updateCitadelPerAsset();
  await fundingCvx.connect(keeper).updateCitadelPerAsset();
};

module.exports = medianOracleUpdatePrice;
