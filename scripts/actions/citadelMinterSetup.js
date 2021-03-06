const hre = require("hardhat");
const ethers = hre.ethers;
const { address } = require("../utils/helpers");
const { formatUnits, parseUnits } = ethers.utils;
const changeBlockTimestamp = require("./changeBlockTimestamp");

const citadelMinterSetup = async ({
  governance,
  schedule,
  citadelMinter,
  policyOps,
  fundingWbtc,
  fundingCvx,
  citadel,
}) => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const scheduleStartTime = blockBefore.timestamp + 6;
  await schedule.connect(governance).setMintingStart(scheduleStartTime);

  // control the time to fast forward
  const depositTokenTime = scheduleStartTime + 1 * 86400;
  await changeBlockTimestamp(depositTokenTime);

  // set distribution split
  await citadelMinter
    .connect(policyOps)
    .setCitadelDistributionSplit(4000, 3000, 2000, 1000);

  // set funding pool rate
  await citadelMinter
    .connect(policyOps)
    .setFundingPoolWeight(address(fundingWbtc), 5000);
  await citadelMinter
    .connect(policyOps)
    .setFundingPoolWeight(address(fundingCvx), 5000);

  // mint and distribute xCTDL to the staking contract
  await citadelMinter.connect(policyOps).mintAndDistribute();
  console.log(
    `supply of CTDL in WBTC Funding pool: ${formatUnits(
      await citadel.balanceOf(address(fundingWbtc)),
      18
    )}`
  );
  console.log(
    `supply of CTDL in CVX Funding pool: ${formatUnits(
      await citadel.balanceOf(address(fundingCvx)),
      18
    )}`
  );

  return {
    blockNumBefore,
    blockBefore,
    scheduleStartTime,
    depositTokenTime,
  };
};

module.exports = citadelMinterSetup;
