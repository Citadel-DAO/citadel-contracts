const fs = require("fs");
const path = require("path");

const hre = require("hardhat");

const StakedCitadelLockerArtifact = require("../artifacts-external/StakedCitadelLocker.json");
const ethers = hre.ethers;

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

  const wBTC = await ethers.getContractFactory("WrapBitcoin");
  const CVX = await ethers.getContractFactory("Convex");
  const USDC = await ethers.getContractFactory("USDC");

  const mintTo = signers[0].address

  const wbtc = await wBTC.deploy(); //
  await wbtc.mint(mintTo, ethers.BigNumber.from("100000000"));

  const cvx = await CVX.deploy(); //
  await cvx.mint(mintTo, ethers.constants.WeiPerEther);

  const usdc = await USDC.deploy(); //
  await usdc.mint(mintTo, ethers.BigNumber.from("100000000000"));

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
  console.log("fundingWbtc address is: ", wbtc.address);

  const fundingCvx = await Funding.deploy();
  console.log("fundingCvx address is: ", cvx.address);

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
    .initialize(address(xCitadel), address(gac), "Vote Locked xCitadel", "vlCTDL");
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
    start: new Date(new Date().getTime() + 10 * 1000),
    duration: 7 * 24 * 3600 * 1000,
    citadelWbtcPrice: ethers.utils.parseUnits("21", 18), // 21 CTDL per wBTC
    wbtcLimit: ethers.utils.parseUnits("100", 8), // 100 wBTC
  };

  // TODO: need to deploy a guest list contract, address 0 won't run
  // await knightingRound.connect(governance).initialize(
  //   address(gac),
  //   address(citadel),
  //   address(wbtc),
  //   knightingRoundParams.start,
  //   knightingRoundParams.duration,
  //   knightingRoundParams.citadelWbtcPrice,
  //   address(governance),
  //   address(0), // TODO: Add guest list and test with it
  //   knightingRoundParams.wbtcLimit
  // );

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

  /// =================================== ///
  // Storing the contract addresses for accessing in helper scripts

  const scriptsDirectory = path.join(__dirname, "..", "scripts-data");
  if (!fs.existsSync(scriptsDirectory)) {
    fs.mkdirSync(scriptsDirectory);
  }
  fs.unlinkSync(path.join(scriptsDirectory, "testnet-addresses.json"))
  fs.writeFileSync(
    path.join(scriptsDirectory, "testnet-addresses.json"),
    JSON.stringify({
      gac: address(gac),
      citadel: address(citadel),
      xCitadel: address(xCitadel),
      xCitadelVester: address(xCitadelVester),
      xCitadelLocker: address(xCitadelLocker),
      schedule: address(schedule),
      citadelMinter: address(citadelMinter),
      knightingRound: address(knightingRound),
      wbtc: address(wbtc),
      cvx: address(cvx),
    }),
    (err) => {
      if (err) {
        console.error(err);
        return;
      }
    }
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
