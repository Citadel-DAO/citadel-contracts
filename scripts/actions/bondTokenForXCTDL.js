const hre = require("hardhat");
const ethers = hre.ethers;
const { address } = require("../utils/helpers");

const { formatUnits, parseUnits } = ethers.utils;

const FundingBonder = require("./FundingBonder");

const bondTokenForXCTDL = async ({
  fundingWbtc,
  fundingCvx,
  user,
  xCitadel,
  wbtc,
  cvx,
}) => {
  // bond some WBTC and CVX to get xCTDL
  const apeWbtcAmount = parseUnits("1", 8);
  const apeCvxAmount = parseUnits("10000", 18);

  const fundingBonder = FundingBonder({ user, slippage: 0 });

  await fundingBonder({
    funding: fundingWbtc,
    amount: apeWbtcAmount,
    token: wbtc,
  });

  await fundingBonder({
    funding: fundingCvx,
    amount: apeCvxAmount,
    token: cvx,
  });

  // user should be getting ~200 xCTDL
  console.log(
    `balance of xCTDL after two deposits: ${formatUnits(
      await xCitadel.balanceOf(address(user)),
      18
    )}`
  );

  return {
    apeWbtcAmount,
    apeCvxAmount,
  };
};

module.exports = bondTokenForXCTDL;
