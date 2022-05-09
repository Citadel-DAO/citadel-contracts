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
const storeConfigs = require("./utils/storeConfigs");

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

  const mintTo = signers[0].address;

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

  /// ======== Grant roles

  await grantRoles(gac, governance, getRoleSigners, { citadelMinter });

  /// =================================== ///
  // Storing the contract addresses for accessing in helper scripts

  storeConfigs(
    path.join(__dirname, "..", "scripts-data"),
    "testnet-addresses",
    {
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
    }
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
