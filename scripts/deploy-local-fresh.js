const hre = require("hardhat");
const ethers = hre.ethers;
const getContractFactories = require("./utils/getContractFactories");
const deployContracts = require("./utils/deployContracts");
const getRoleSigners = require("./utils/getRoleSingers");
const { address, hashIt } = require("./utils/helpers");
const grantRoles = require("./utils/grantRoles");
const initializer = require("./actions/initializer");

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";

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

  const wbtc = ERC20Upgradeable.attach(wbtc_address); //
  const cvx = ERC20Upgradeable.attach(cvx_address); //

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

  console.log("Initialize GAC...");

  await initializer({
    gac,
    citadel,
    xCitadel,
    xCitadelVester,
    xCitadelLocker,
    citadelMinter,
    schedule,
    fundingWbtc,
    fundingCvx,
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

  /// ======== Grant roles
  await grantRoles(gac, governance, getRoleSigners, { citadelMinter });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
