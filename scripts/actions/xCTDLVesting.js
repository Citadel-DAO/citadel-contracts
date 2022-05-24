const hre = require("hardhat");
const ethers = hre.ethers;
const { address } = require("../utils/helpers");
const { formatUnits, parseUnits } = ethers.utils;
const changeBlockTimestamp = require("./changeBlockTimestamp");

const xCTDLVesting = async ({
  xCitadel,
  user,
  xCitadelVester,
  citadel,
  xCitadelLocker,
  citadelMinter,
  policyOps,
}) => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);

  // withdraw some xCTDL to start vesting
  await xCitadel.connect(user).withdraw(parseUnits("50", 18));

  // fast forward to get some CTDL vested
  console.log(
    `fast forward to 10 days later to have some vested CTDL unlocked`
  );
  const getVestedTime = blockBefore.timestamp + 10 * 86400;
  await changeBlockTimestamp(getVestedTime);

  // claim some vested CTDL
  await xCitadelVester.claim(address(user), parseUnits("20", 18));
  console.log(
    `got ${formatUnits(
      await citadel.balanceOf(address(user)),
      18
    )} CTDL 10 days later`
  );

  // before lock up, need to allow xCTDL
  await xCitadel
    .connect(user)
    .approve(address(xCitadelLocker), parseUnits("150", 18));

  // lock up some xCTDL
  console.log(`locking up 50 xCTDL`);
  await xCitadelLocker
    .connect(user)
    .lock(address(user), parseUnits("50", 18), 0);
  console.log(
    `balance of xCTDL after lock: ${formatUnits(
      await xCitadel.balanceOf(address(user)),
      18
    )}`
  );

  // fast forward to make a position unlockable
  console.log(`fast forward to 22 weeks later to make the position unlockable`);
  const unlockTime = getVestedTime + 7 * 22 * 86400; // 22 weeks later

  await changeBlockTimestamp(unlockTime);

  await xCitadelLocker.checkpointEpoch();
  await citadelMinter.connect(policyOps).mintAndDistribute();
  // // test out if i can withdraw
  // await xCitadelLocker.connect(user).withdrawExpiredLocksTo(address(user));
  // console.log(
  //   `rewards: ${await xCitadelLocker.claimableRewards(address(user))}`
  // );

  // make another locked position
  console.log(`lock another 100 xCTDL to make the position locked`);
  await xCitadelLocker
    .connect(user)
    .lock(address(user), parseUnits("100", 18), 0);

  // to make some rewards available
  const cannotUnlockTime = unlockTime + 7 * 5 * 86400; // 5 weeks later
  await changeBlockTimestamp(cannotUnlockTime);

  await xCitadelLocker.checkpointEpoch();
  console.log(
    `total locked position: ${formatUnits(
      await xCitadelLocker.lockedBalanceOf(address(user)),
      18
    )}`
  );
};

module.exports = xCTDLVesting;
