const hre = require("hardhat");
const ethers = hre.ethers;
const { address } = require("../utils/helpers");

const { formatUnits, parseUnits } = ethers.utils;

const bondTokenForXCTDL = async ({
  fundingWbtc,
  fundingCvx,
  apeWbtcAmount,
  apeCvxAmount,
  user,
  xCitadel,
}) => {
  // bond some WBTC and CVX to get xCTDL

  await fundingWbtc.connect(user).deposit(parseUnits("1", 8), 0); // max slippage as there's no competition
  await fundingCvx.connect(user).deposit(apeCvxAmount, 0); // max slippage as there's no competition

  // user should be getting ~200 xCTDL
  console.log(
    `balance of xCTDL after two deposits: ${formatUnits(
      await xCitadel.balanceOf(address(user)),
      18
    )}`
  );
};

module.exports = bondTokenForXCTDL;
