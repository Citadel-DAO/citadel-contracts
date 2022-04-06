const hre = require("hardhat");
const ethers = hre.ethers;

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";

const address = (entity) => entity.address;

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
  const StakedCitadelLocker = await ethers.getContractFactory(
    "StakedCitadelLocker"
  );

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

  const wbtc = ERC20Upgradeable.attach(wbtc_address); //
  const cvx = ERC20Upgradeable.attach(cvx_address); //

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

  citadel.connect(governance).initialize("Citadel", "CTDL", gac.address);

  /// ======= Staked (x) Citadel Vault Token

  const xCitadelFees = [0, 0, 0, 0];

  xCitadel
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
  xCitadelVester
    .connect(governance)
    .initialize(address(gac), address(citadel), address(xCitadel));

  /// =======  xCitadelLocker
  xCitadelLocker
    .connect(governance)
    .initialize(address(xCitadel), "Vote Locked xCitadel", "vlCTDL");

  // ========  SupplySchedule || CTDL Token Distribution
  schedule.connect(governance).initialize(address(gac));

  // ========  CitadelMinter || CTDLMinter
  citadelMinter
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
    start: new Date(new Date().getTime() + 10 * 1000),
    duration: 7 * 24 * 3600 * 1000,
    citadelWbtcPrice: ethers.utils.parseUnits("23", 18), // 21 CTDL per wBTC
    wbtcLimit: ethers.utils.parseUnits("100", 8), // 100 wBTC
  };

  knightingRound.connect(governance).initialize(
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
  fundingWbtc.initialize(
    address(gac),
    address(citadel),
    address(wbtc),
    address(xCitadel),
    address(treasuryVault),
    eoaOracle,
    ethers.utils.parseUnits("100", 8)
  );
  fundingCvx.initialize(
    address(gac),
    address(citadel),
    address(cvx),
    address(xCitadel),
    address(treasuryVault),
    address(eoaOracle),
    ethers.utils.parseUnits("100000", 18)
  );

  /// ======== Grant roles

  gac
    .connect(governance)
    .grantRole(hashIt("CONTRACT_GOVERNANCE_ROLE"), address(governance));
  gac
    .connect(governance)
    .grantRole(hashIt("TREASURY_GOVERNANCE_ROLE"), address(treasuryVault));

  gac
    .connect(governance)
    .grantRole(hashIt("TECH_OPERATIONS_ROLE"), address(techOps));
  gac
    .connect(governance)
    .grantRole(hashIt("TREASURY_OPERATIONS_ROLE"), address(treasuryOps));
  gac
    .connect(governance)
    .grantRole(hashIt("POLICY_OPERATIONS_ROLE"), address(policyOps));

  gac
    .connect(governance)
    .grantRole(hashIt("CITADEL_MINTER_ROLE"), address(citadelMinter));
  gac
    .connect(governance)
    .grantRole(hashIt("CITADEL_MINTER_ROLE"), address(governance));

  gac.connect(governance).grantRole(hashIt("PAUSER_ROLE"), address(governance));
  gac.connect(governance).grantRole(hashIt("UNPAUSER_ROLE"), address(techOps));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
