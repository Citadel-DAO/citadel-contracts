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
  const tokens = [
    "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b",
  ];
};

module.exports = medianOracleUpdatePrice;
