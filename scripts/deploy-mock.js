const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const path = require("path");
const getContractFactories = require("./utils/getContractFactories");
const deployContracts = require("./utils/deployContracts");
const getRoleSigners = require("./utils/getRoleSingers");
const { address, hashIt } = require("./utils/helpers");
const grantRoles = require("./utils/grantRoles");
const initializer = require("./actions/initializer");

async function main() {
  const signers = await ethers.getSigners();

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
    wBTC,
    CVX,
    USDC,
  } = await getContractFactories();

  const mintTo = signers[0].address;

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
    fundingWbtc,
    fundingCvx,
    wbtc,
    cvx,
    usdc,
  } = await deployContracts([
    { factory: GlobalAccessControl, instance: "gac" },
    { factory: CitadelToken, instance: "citadel" },
    { factory: StakedCitadel, instance: "xCitadel" },
    { factory: StakedCitadelVester, instance: "xCitadelVester" },
    { factory: StakedCitadelLocker, instance: "xCitadelLocker" },
    { factory: SupplySchedule, instance: "schedule" },
    { factory: CitadelMinter, instance: "citadelMinter" },
    { factory: KnightingRound, instance: "knightingRound" },
    { factory: Funding, instance: "fundingWbtc" },
    { factory: Funding, instance: "fundingCvx" },
    { factory: wBTC, instance: "wbtc" },
    { factory: CVX, instance: "cvx" },
    { factory: USDC, instance: "usdc" },
  ]);

  await wbtc.mint(mintTo, ethers.BigNumber.from("100000000"));
  await cvx.mint(mintTo, ethers.constants.WeiPerEther);
  await usdc.mint(mintTo, ethers.BigNumber.from("100000000000"));

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
    fundingWbtc,
    fundingCvx
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
    eoaOracle
  });

  /// ========  Knighting Round
  //const knightingRoundParams = {
  //  start: new Date(new Date().getTime() + 10 * 1000),
  //  duration: 7 * 24 * 3600 * 1000,
  //  citadelWbtcPrice: ethers.utils.parseUnits("21", 18), // 21 CTDL per wBTC
  //  wbtcLimit: ethers.utils.parseUnits("100", 8), // 100 wBTC
  //};

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
 

  /// ======== Grant roles

  await grantRoles(gac, governance, getRoleSigners, { citadelMinter });

  /// =================================== ///
  // Storing the contract addresses for accessing in helper scripts

  const scriptsDirectory = path.join(__dirname, "..", "scripts-data");
  if (!fs.existsSync(scriptsDirectory)) {
    fs.mkdirSync(scriptsDirectory);
  }
  fs.unlinkSync(path.join(scriptsDirectory, "testnet-addresses.json"));
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
