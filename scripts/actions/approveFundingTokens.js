const { parseUnits } = ethers.utils;
const { address } = require("../utils/helpers");

const approveFundingTokens = async ({ wbtc, cvx, fundingCvx, fundingWbtc }) => {
  const apeWbtcAmount = parseUnits("10", 8);
  const apeCvxAmount = parseUnits("1000", 18);
  await wbtc.approve(address(fundingWbtc), apeWbtcAmount);
  await cvx.approve(address(fundingCvx), apeCvxAmount);
};

module.exports = approveFundingTokens;
