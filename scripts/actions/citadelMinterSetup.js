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
  citadel,
  fundingRegistry,
  Funding,
}) => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const scheduleStartTime = blockBefore.timestamp + 6;
  await schedule.connect(governance).setMintingStart(scheduleStartTime);

  // control the time to fast forward
  const depositTokenTime = scheduleStartTime + 1 * 20 * 86400;
  await changeBlockTimestamp(depositTokenTime);

  // set distribution split
  await citadelMinter
    .connect(policyOps)
    .setCitadelDistributionSplit(4000, 3000, 2000, 1000);

  // set funding pool rate
  const fundingsList = await fundingRegistry.getAllFundings();

  const setAllPoolWieght = async (i = 0) => {
    const currentFunding = fundingsList[i]
      ? Funding.attach(fundingsList[i])
      : undefined;
    if (!currentFunding) return;

    console.log(
      "setting up minter funding pool weight: ",
      currentFunding.address
    );

    await citadelMinter
      .connect(policyOps)
      .setFundingPoolWeight(address(currentFunding), 5000);

    return await setAllPoolWieght(i + 1);
  };

  await setAllPoolWieght();

  // mint and distribute xCTDL to the staking contract
  await citadelMinter.connect(policyOps).mintAndDistribute();

  console.log(
    `supply of CTDL in each funding pool: ${formatUnits(
      await citadel.balanceOf(fundingsList[0]),
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
