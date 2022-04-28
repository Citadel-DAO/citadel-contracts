const hre = require("hardhat");
const StakedCitadelLockerArtifact = require("../artifacts-external/StakedCitadelLocker.json");
const ethers = hre.ethers;

const { formatUnits, parseUnits } = ethers.utils;

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";

const wbtc_minter_address = "0xCA06411bd7a7296d7dbdd0050DFc846E95fEBEB7"; // owner address of wbtc
const cvx_minter_address = "0xF403C135812408BFbE8713b5A23a04b3D48AAE31"; // operator address of cvx

const erc20_mintable_abi = ["function mint(address, uint256)"];

const address = (entity) =>
  entity.address ? entity.address : ethers.constants.AddressZero;

const hashIt = (str) => ethers.utils.keccak256(ethers.utils.toUtf8Bytes(str));

async function main() {
  const signers = await ethers.getSigners();

  /// === Contract Factories
  const GlobalAccessControl = await ethers.getContractFactory(
    "GlobalAccessControl"
  );

  const CitadelToken = await ethers.getContractFactory("CitadelToken");
  const StakedCitadel = await ethers.getContractFactory("StakedCitadel");
  const StakedCitadelVester = await ethers.getContractFactory(
    "StakedCitadelVester"
  );
  const StakedCitadelLocker = await ethers.getContractFactoryFromArtifact({
    ...StakedCitadelLockerArtifact,
    _format: "hh-sol-artifact-1",
    contractName: "StakedCitadelLocker",
    sourceName: "src/StakedCitadelLocker.sol",
    linkReferences: {
      ...StakedCitadelLockerArtifact.bytecode.linkReferences,
      ...StakedCitadelLockerArtifact.deployedBytecode.linkReferences,
    },
    deployedLinkReferences: {
      ...StakedCitadelLockerArtifact.bytecode.deployedLinkReferences,
      ...StakedCitadelLockerArtifact.deployedBytecode.deployedLinkReferences,
    },
    bytecode: StakedCitadelLockerArtifact.bytecode.object,
    deployedBytecode: StakedCitadelLockerArtifact.deployedBytecode.object,
  });

  const SupplySchedule = await ethers.getContractFactory("SupplySchedule");
  const CitadelMinter = await ethers.getContractFactory("CitadelMinter");

  const KnightingRound = await ethers.getContractFactory("KnightingRound");

  const Funding = await ethers.getContractFactory("Funding");

  const ERC20Upgradeable = await ethers.getContractFactory("ERC20Upgradeable");

  /// === Deploying Contracts & loggin addresses
  const gac = await GlobalAccessControl.deploy();
  console.log("global access control address is: ", gac.address);

  const citadel = await CitadelToken.deploy();
  console.log("citadel address is: ", citadel.address);

  const xCitadel = await StakedCitadel.deploy();
  console.log("xCitadel address is: ", xCitadel.address);

  const xCitadelVester = await StakedCitadelVester.deploy();
  console.log("xCitadelVester address is: ", xCitadelVester.address);

  const xCitadelLocker = await StakedCitadelLocker.deploy();
  console.log("xCitadelLocker address is: ", xCitadelLocker.address);

  const schedule = await SupplySchedule.deploy();
  console.log("schedule address is: ", schedule.address);

  const citadelMinter = await CitadelMinter.deploy();
  console.log("citadelMinter address is: ", citadelMinter.address);

  const knightingRound = await KnightingRound.deploy();
  console.log("knightingRound address is: ", knightingRound.address);

  const fundingWbtc = await Funding.deploy();
  console.log("fundingWbtc address is: ", knightingRound.address);

  const fundingCvx = await Funding.deploy();
  console.log("fundingCvx address is: ", knightingRound.address);

  /// === mint wbtc and cvx to signers[0]
  // impersonate the token owner
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [wbtc_minter_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [cvx_minter_address],
  });

  // send some balance for the gas
  await hre.network.provider.send("hardhat_setBalance", [
    wbtc_minter_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    cvx_minter_address,
    "0x1000000000000000000",
  ]);

  // get the signer
  const wbtc_minter = await ethers.getSigner(wbtc_minter_address);
  const cvx_minter = await ethers.getSigner(cvx_minter_address);

  // connect the token contract to signers
  const wbtcMintable = new ethers.Contract(
    wbtc_address,
    erc20_mintable_abi,
    wbtc_minter
  );

  const cvxMintable = new ethers.Contract(
    cvx_address,
    erc20_mintable_abi,
    cvx_minter
  );

  // mint some tokens to signers[0]
  const user = signers[0];
  const txWbtcMint = await wbtcMintable.mint(
    address(user),
    parseUnits("100", 8) // 100 btc
  );
  await txWbtcMint.wait();
  await cvxMintable.mint(
    address(user),
    parseUnits("100000", 18) // 100000 cvx
  );

  const wbtc = ERC20Upgradeable.attach(wbtc_address); //
  const cvx = ERC20Upgradeable.attach(cvx_address); //

  // check the balance
  const balance_wbtc = await wbtc.balanceOf(address(user));
  console.log(`wbtc balance of signers[0]: ${formatUnits(balance_wbtc, 8)}`);
  const balance_cvx = await cvx.balanceOf(address(user));
  console.log(`cvx balance of signers[0]: ${formatUnits(balance_cvx, 18)}`);

  /// === Variable Setup
  const governance = signers[12];
  const keeper = signers[11];
  const guardian = signers[13];
  const treasuryVault = signers[14];
  const techOps = signers[15];
  const treasuryOps = signers[18];
  const citadelTree = signers[16];
  const policyOps = signers[19];

  const rando = signers[17];

  const whale = signers[7];
  const shrimp = signers[8];
  const shark = signers[9];

  const eoaOracle = signers[3];

  /// === Initialization and Setup

  /// ======= Global Access Control

  await gac.connect(governance).initialize(governance.address);

  /// ======= Citadel Token

  await citadel.connect(governance).initialize("Citadel", "CTDL", gac.address);

  /// ======= Staked (x) Citadel Vault Token

  const xCitadelFees = [0, 0, 0, 0];

  await xCitadel
    .connect(governance)
    .initialize(
      address(citadel),
      address(governance),
      address(keeper),
      address(guardian),
      address(treasuryVault),
      address(techOps),
      address(citadelTree),
      address(xCitadelVester),
      "Staked Citadel",
      "xCTDL",
      xCitadelFees
    );

  /// ======= Vested Exit | xCitadelVester
  await xCitadelVester
    .connect(governance)
    .initialize(address(gac), address(citadel), address(xCitadel));

  /// =======  xCitadelLocker
  await xCitadelLocker
    .connect(governance)
    .initialize(address(xCitadel), "Vote Locked xCitadel", "vlCTDL");
  // add reward token to be distributed to staker
  await xCitadelLocker
    .connect(governance)
    .addReward(address(xCitadel), address(citadelMinter), true);

  // ========  SupplySchedule || CTDL Token Distribution
  await schedule.connect(governance).initialize(address(gac));

  // ========  CitadelMinter || CTDLMinter
  await citadelMinter
    .connect(governance)
    .initialize(
      address(gac),
      address(citadel),
      address(xCitadel),
      address(xCitadelLocker),
      address(schedule)
    );

  /// ========  Knighting Round
  const knightingRoundParams = {
    start: Number(new Date(new Date().getTime())),
    duration: 7 * 24 * 3600 * 1000,
    citadelWbtcPrice: ethers.utils.parseUnits("21", 18), // 21 CTDL per wBTC
    wbtcLimit: ethers.utils.parseUnits("100", 8), // 100 wBTC
  };

  // TODO: need to deploy a guest list contract, address 0 won't run
  await knightingRound.connect(governance).initialize(
    address(gac),
    address(citadel),
    address(wbtc),
    knightingRoundParams.start,
    knightingRoundParams.duration,
    knightingRoundParams.citadelWbtcPrice,
    address(governance),
    address(0), // TODO: Add guest list and test with it
    knightingRoundParams.wbtcLimit
  );

  /// ========  Funding
  await fundingWbtc.initialize(
    address(gac),
    address(citadel),
    address(wbtc),
    address(xCitadel),
    address(treasuryVault),
    address(eoaOracle),
    ethers.utils.parseUnits("100", 8)
  );
  await fundingCvx.initialize(
    address(gac),
    address(citadel),
    address(cvx),
    address(xCitadel),
    address(treasuryVault),
    address(eoaOracle),
    ethers.utils.parseUnits("100000", 18)
  );

  /// ======== Grant roles

  await gac
    .connect(governance)
    .grantRole(hashIt("CONTRACT_GOVERNANCE_ROLE"), address(governance));
  await gac
    .connect(governance)
    .grantRole(hashIt("TREASURY_GOVERNANCE_ROLE"), address(treasuryVault));

  await gac
    .connect(governance)
    .grantRole(hashIt("TECH_OPERATIONS_ROLE"), address(techOps));
  await gac
    .connect(governance)
    .grantRole(hashIt("TREASURY_OPERATIONS_ROLE"), address(treasuryOps));
  await gac
    .connect(governance)
    .grantRole(hashIt("POLICY_OPERATIONS_ROLE"), address(policyOps));

  await gac
    .connect(governance)
    .grantRole(hashIt("CITADEL_MINTER_ROLE"), address(citadelMinter));
  await gac
    .connect(governance)
    .grantRole(hashIt("CITADEL_MINTER_ROLE"), address(governance));

  await gac
    .connect(governance)
    .grantRole(hashIt("PAUSER_ROLE"), address(governance));
  await gac
    .connect(governance)
    .grantRole(hashIt("UNPAUSER_ROLE"), address(techOps));

  console.log(`finished initialization, now making positions...`);

  // ======== make some positions for the signers[0]
  // set supply schedule start
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const scheduleStartTime = blockBefore.timestamp + 6;
  await schedule.connect(governance).setMintingStart(scheduleStartTime);

  // control the time to fast forward
  const depositTokenTime = scheduleStartTime + 1 * 86400;
  await hre.network.provider.send("evm_setNextBlockTimestamp", [
    depositTokenTime,
  ]);
  await hre.network.provider.send("evm_mine");

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
    .functions["updateCitadelPriceInAsset(uint256)"](parseUnits("21", 18));
  await fundingCvx
    .connect(eoaOracle)
    .functions["updateCitadelPriceInAsset(uint256)"](parseUnits("0.21", 18));

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
  // console.log(
  //   `fast forward to 10 days later to have some vested CTDL unlocked`
  // );
  // const getVestedTime = depositTokenTime + 10 * 86400;
  // await hre.network.provider.send("evm_setNextBlockTimestamp", [getVestedTime]);
  // await hre.network.provider.send("evm_mine");

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

  // // fast forward to make a position unlockable
  // console.log(`fast forward to 22 weeks later to make the position unlockable`);
  // const unlockTime = getVestedTime + 7 * 22 * 86400; // 22 weeks later
  // await hre.network.provider.send("evm_setNextBlockTimestamp", [unlockTime]);
  // await hre.network.provider.send("evm_mine");

  // await xCitadelLocker.checkpointEpoch();
  // await citadelMinter.connect(policyOps).mintAndDistribute();


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
  // const cannotUnlockTime = unlockTime + 7 * 5 * 86400; // 5 weeks later
  // await hre.network.provider.send("evm_setNextBlockTimestamp", [
  //   cannotUnlockTime,
  // ]);
  // await hre.network.provider.send("evm_mine");

  // await xCitadelLocker.checkpointEpoch();
  // console.log(
  //   `total locked position: ${formatUnits(
  //     await xCitadelLocker.lockedBalanceOf(address(user)),
  //     18
  //   )}`
  // );
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
  // );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
