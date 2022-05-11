const hre = require("hardhat");
const ethers = hre.ethers;
const deployLocal = require("./actions/deployLocal");
//const getContractFactories = require("./utils/getContractFactories");
//const deployContracts = require("./utils/deployContracts");
//const getRoleSigners = require("./utils/getRoleSingers");
//const grantRoles = require("./utils/grantRoles");
//const { address } = require("./utils/helpers");
//const initializer = require("./actions/initializer");
//const changeBlockTimestamp = require("./utils/changeBlockTimestamp");
//
//const { formatUnits, parseUnits } = ethers.utils;
//
//const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
//const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";
//
//const wbtc_minter_address = "0xCA06411bd7a7296d7dbdd0050DFc846E95fEBEB7"; // owner address of wbtc
//const cvx_minter_address = "0xF403C135812408BFbE8713b5A23a04b3D48AAE31"; // operator address of cvx
//
//const erc20_mintable_abi = ["function mint(address, uint256)"];

async function main() {
  const signers = await ethers.getSigners();

  await deployLocal();

  /// === Contract Factories
  /* const {
    GlobalAccessControl,
    CitadelToken,
    StakedCitadelVester,
    StakedCitadel,
    StakedCitadelLocker,
    SupplySchedule,
    CitadelMinter,
    KnightingRound,
    Funding,
    ERC20Upgradeable,
    KnightingRoundGuestlist,
  } = await getContractFactories();

  /// === Deploying Contracts & loggin addresses
  const {
    gac,
    citadel,
    xCitadel,
    xCitadelVester,
    xCitadelLocker,
    schedule,
    citadelMinter,
    knightingRound,
    knightingRoundGuestlist,
    fundingWbtc,
    fundingCvx,
  } = await deployContracts([
    { factory: GlobalAccessControl, instance: "gac" },
    { factory: CitadelToken, instance: "citadel" },
    { factory: StakedCitadel, instance: "xCitadel" },
    { factory: StakedCitadelVester, instance: "xCitadelVester" },
    { factory: StakedCitadelLocker, instance: "xCitadelLocker" },
    { factory: SupplySchedule, instance: "schedule" },
    { factory: CitadelMinter, instance: "citadelMinter" },
    { factory: KnightingRound, instance: "knightingRound" },
    { factory: KnightingRoundGuestlist, instance: "knightingRoundGuestlist" },
    { factory: Funding, instance: "fundingWbtc" },
    { factory: Funding, instance: "fundingCvx" },
  ]);

  /// === mint wbtc and cvx to signers[0]
  // impersonate the token owner
  

  /// === Variable Setup
  const {
    governance,
    keeper,
    guardian,
    treasuryVault,
    techOps,
    treasuryOps,
    citadelTree,
    policyOps,
    eoaOracle,
  } = await getRoleSigners();

  /// === Initialization and Setup

  const xCitadelFees = [0, 0, 0, 0];

  await initializer({
    gac,
    citadel,
    xCitadel,
    xCitadelVester,
    xCitadelLocker,
    citadelMinter,
    schedule,
  })({
    governance,
    xCitadelFees,
    keeper,
    guardian,
    treasuryVault,
    techOps,
    citadelTree,
    wbtc,
    cvx,
    eoaOracle,
  });

  /// ======== Grant roles

  await grantRoles(gac, governance, getRoleSigners, { citadelMinter });

  console.log(`finished initialization, now making positions...`);

  // ======== make some positions for the signers[0]
  // set supply schedule start
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
    .setCitadelDistributionSplit(4000, 3000, 3000);

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

  // approve the tokens to funding
  const apeWbtcAmount = parseUnits("10", 8);
  const apeCvxAmount = parseUnits("1000", 18);
  await wbtc.approve(address(fundingWbtc), apeWbtcAmount);
  await cvx.approve(address(fundingCvx), apeCvxAmount);

  // eoa oracle update the price
  await fundingWbtc
    .connect(eoaOracle)
    .functions["updateCitadelPerAsset(uint256)"](parseUnits("21", 18));
  await fundingCvx
    .connect(eoaOracle)
    .functions["updateCitadelPerAsset(uint256)"](parseUnits("0.21", 18));

  // set max discount
  await fundingWbtc.connect(governance).setDiscountLimits(0, 1000);
  await fundingCvx.connect(governance).setDiscountLimits(0, 1000);

  // set a discount
  await fundingWbtc.connect(policyOps).setDiscount(1000); // 10 percent discount
  await fundingCvx.connect(policyOps).setDiscount(1000); // 10 percent discount

  // bond some WBTC and CVX to get xCTDL
  await fundingWbtc.connect(user).deposit(apeWbtcAmount, 0); // max slippage as there's no competition
  await fundingCvx.connect(user).deposit(apeCvxAmount, 0); // max slippage as there's no competition
  // user should be getting ~200 xCTDL
  console.log(
    `balance of xCTDL after two deposits: ${formatUnits(
      await xCitadel.balanceOf(address(user)),
      18
    )}`
  );

  // withdraw some xCTDL to start vesting
  await xCitadel.connect(user).withdraw(parseUnits("50", 18));

  // fast forward to get some CTDL vested
  console.log(
    `fast forward to 10 days later to have some vested CTDL unlocked`
  );
  const getVestedTime = depositTokenTime + 10 * 86400;
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
  // // test out if there are rewards available
  // console.log(
  //   `balance of xCTDL before claim rewards: ${formatUnits(
  //     await xCitadel.balanceOf(address(user)),
  //     18
  //   )}`
  // );
  // await xCitadelLocker.functions["getReward(address)"](address(user));
  // console.log(
  //   `balance of xCTDL after second lock: ${formatUnits(
  //     await xCitadel.balanceOf(address(user)),
  //     18
  //   )}`
  // ); */
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
