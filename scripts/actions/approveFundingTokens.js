const { parseUnits } = ethers.utils;
const { address } = require("../utils/helpers");

const approveFundingTokens = async ({
  wbtc,
  cvx,
  fundingCvx,
  fundingWbtc,
  user,
}) => {
  const apeWbtcAmount = parseUnits("1", 8);
  const apeCvxAmount = parseUnits("1000", 18);

  await wbtc.connect(user).approve(address(fundingWbtc), apeWbtcAmount);
  await cvx.approve(address(fundingCvx), apeCvxAmount);

  return {
    apeWbtcAmount,
    apeCvxAmount,
  };
};

module.exports = approveFundingTokens;
