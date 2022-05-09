const hre = require("hardhat");
const StakedCitadelLockerArtifact = require("../artifacts-external/StakedCitadelLocker.json");
const ethers = hre.ethers;
const getContractFactories = require("./utils/getContractFactories");

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";

const address = (entity) =>
  entity.address ? entity.address : ethers.constants.AddressZero;

const hashIt = (str) => ethers.utils.keccak256(ethers.utils.toUtf8Bytes(str));

async function main() {
  const signers = await ethers.getSigners();
  const governance = signers[12];

  /// === Contract Factories

  const {
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
    TransparentUpgradeableProxy,
    ProxyAdmin,
  } = await getContractFactories();
  const proxyAdmin = await ProxyAdmin.deploy();
  await proxyAdmin.transferOwnership(governance);

  /// === Deploying Contracts & loggin addresses
  const gac = await GlobalAccessControl.deploy();
  console.log("global access control address is: ", gac.address);

  const citadel = await CitadelToken.deploy();
  console.log("citadel address is: ", citadel.address);

  const xCitadel = await StakedCitadel.deploy();
  console.log("xCitadel address is: ", xCitadel.address);

  const xCitadelVesterLogic = await StakedCitadelVester.deploy();
  const xCitadelVester = await TransparentUpgradeableProxy.deploy(
    xCitadelVesterLogic,
    proxyAdmin
  );

  console.log("xCitadelVester address is: ", xCitadelVester.address);

  const xCitadelLockerLogic = await StakedCitadelLocker.deploy();
  const xCitadelLockerProxy = await TransparentUpgradeableProxy.deploy(
    xCitadelLockerLogic,
    proxyAdmin
  );
  console.log("xCitadelLocker address is: ", xCitadelLocker.address);

  const scheduleLogic = await SupplySchedule.deploy();
  const schedule = await TransparentUpgradeableProxy.deploy(
    scheduleLogic,
    proxyAdmin
  );
  console.log("schedule address is: ", schedule.address);

  const citadelMinterLogic = await CitadelMinter.deploy();
  const citadelMinter = await TransparentUpgradeableProxy.deploy(
    citadelMinterLogic,
    proxyAdmin
  );
  console.log("citadelMinter address is: ", citadelMinter.address);

  const knightingRoundLogic = await KnightingRound.deploy();
  const knightingRound = await TransparentUpgradeableProxy.deploy(
    knightingRoundLogic,
    proxyAdmin
  );
  console.log("knightingRound address is: ", knightingRound.address);

  const knightingRoundGuestlistLogic = await KnightingRoundGuestlist.deploy();
  const knightingRoundGuestlist = await TransparentUpgradeableProxy.deploy(
    knightingRoundGuestlistLogic,
    proxyAdmin
  );
  console.log(
    "knightingRoundGuestlist address is: ",
    knightingRoundGuestlist.address
  );

  const fundingWbtcLogic = await Funding.deploy();
  const fundingWbtc = await TransparentUpgradeableProxy.deploy(
    fundingWbtcLogic,
    proxyAdmin
  );
  console.log("fundingWbtc address is: ", knightingRound.address);

  const fundingCvxLogic = await Funding.deploy();
  const fundingCvx = await TransparentUpgradeableProxy.deploy(
    fundingCvxLogic,
    proxyAdmin
  );
  console.log("fundingCvx address is: ", knightingRound.address);

  const wbtc = ERC20Upgradeable.attach(wbtc_address); //
  const cvx = ERC20Upgradeable.attach(cvx_address); //

  /// === Variable Setup
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

  console.log(governance);
  console.log(governance.address);

  console.log("Initialize GAC...");
  await gac.connect(governance).initialize(governance.address);

  /// ======= Citadel Token

  console.log("Initialize Citadel Token...");
  await citadel.connect(governance).initialize("Citadel", "CTDL", gac.address);

  /// ======= Staked (x) Citadel Vault Token

  console.log("Initialize xCitadel Token...");

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
  console.log("Initialize xCitadelVester...");
  await xCitadelVester
    .connect(governance)
    .initialize(address(gac), address(citadel), address(xCitadel));

  /// =======  xCitadelLocker
  console.log("Initialize xCitadelLocker...");
  await xCitadelLocker
    .connect(governance)
    .initialize(address(xCitadel), "Vote Locked xCitadel", "vlCTDL");
  // add reward token to be distributed to staker
  await xCitadelLocker
    .connect(governance)
    .addReward(address(xCitadel), address(citadelMinter), true);

  // ========  SupplySchedule || CTDL Token Distribution
  console.log("Initialize supplySchedule...");
  await schedule.connect(governance).initialize(address(gac));

  // ========  CitadelMinter || CTDLMinter
  console.log("Initialize citadelMinter...");
  await citadelMinter
    .connect(governance)
    .initialize(
      address(gac),
      address(citadel),
      address(xCitadel),
      address(xCitadelLocker),
      address(schedule)
    );

  console.log("Initialize knightingRoundGuestlist...");
  // knightingRoundGuestlist.connect(governance).initialize(address(gac));
  // knightingRoundGuestlist.connect(techOps).setGuestRoot("0xa792f206b3e190ce3670653ece23b5ffac811e402f37d3c6d37638e310c2b081");

  /// ========  Knighting Round
  const knightingRoundParams = {
    start: ethers.BigNumber.from(
      ((new Date().getTime() + 1000 * 1000) / 1000).toPrecision(10).toString()
    ),
    duration: ethers.BigNumber.from(14 * 24 * 3600),
    citadelWbtcPrice: ethers.utils.parseUnits("21", 18), // 21 CTDL per wBTC
    wbtcLimit: ethers.utils.parseUnits("100", 8), // 100 wBTC
  };

  console.log(
    knightingRoundParams.start,
    knightingRoundParams.duration,
    knightingRoundParams.citadelWbtcPrice,
    knightingRoundParams.wbtcLimit
  );

  console.log("Initialize knightingRound...");
  // TODO: need to deploy a guest list contract, address 0 won't run
  await knightingRound.connect(governance).initialize(
    address(gac),
    address(citadel),
    address(wbtc),
    knightingRoundParams.start,
    knightingRoundParams.duration,
    knightingRoundParams.citadelWbtcPrice,
    address(treasuryVault),
    address(knightingRoundGuestlist), // TODO: Add guest list and test with it
    knightingRoundParams.wbtcLimit
  );

  // /// ========  Funding
  console.log("Initialize funding...");
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
  console.log("Grant roles...");
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
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
