const hre = require("hardhat");
const ethers = hre.ethers;
const { parseUnits } = ethers.utils;

const pipeActions = require("../utils/pipeActions");
const setupAndDeploy = require("./setupAndDeploy");
const mintForknet = require("./mintForknet");
const getRoleSigners = require("./getRoleSingers");
const initializer = require("./initializer");
const setupLibraries = require("./setupLibraries");
const grantRoles = require("./grantRoles");
const setXCitadelStrategy = require("./setXCitadelStrategy");
const citadelMinterSetup = require("./citadelMinterSetup");
const setDiscount = require("./setDiscount");
const bondTokenForXCTDL = require("./bondTokenForXCTDL");
const xCTDLVesting = require("./xCTDLVesting");
const setupKnightingRound = require("./setupKnightingRound");
const setupSchedule = require("./setupSchedule");

const tokenIns = require("./tokenIns");
const initializeFundingRegistry = require("./initializeFundingRegistry");
const oracleSetupForknet = require("./oracleSetupForknet");
const addOracleProviders = require("./addOracleProviders");

const deployLocal = async () => {
  const signers = await ethers.getSigners();

  const user = signers[0];
  const mintTo = signers[0];
  const xCitadelFees = [0, 0, 0, 0];
  const multisig = signers[2];

  const deployer = new ethers.Wallet(
    "58cebe9f79bba8b181fb81cd821c06f3fab64a8cf3631c3c7ed8c98183a2f035",
    ethers.provider
  );

  // Send 1 ether to an ens name.
  await signers[19].sendTransaction({
    to: deployer.address,
    value: ethers.utils.parseEther("1.0"),
  });

  const apeGeneral = parseUnits("1", 8);

  const apeWbtcAmount = parseUnits("1", 8);
  const apeCvxAmount = parseUnits("1000", 18);

  await pipeActions({
    mintTo,
    xCitadelFees,
    user,
    multisig,
    deployer,
    apeWbtcAmount,
    apeCvxAmount,
    apeGeneral,
  })(
    setupLibraries,
    () => console.log("Setting up libraries ..."),
    setupAndDeploy,
    () => console.log("Contracts setted up ..."),
    mintForknet,
    () => console.log("Forknet mints ..."),
    getRoleSigners,
    () => console.log("Roles assigned ..."),
    initializer,
    () => console.log("Contracts initialized ..."),
    tokenIns,
    () => console.log("tokenIns setted up ..."),
    initializeFundingRegistry,
    () => console.log("Contracts initialized ..."),
    oracleSetupForknet,
    () => console.log("Oracles setup forknet ..."),
    setXCitadelStrategy,
    () => console.log("Setted xCitadel strategy  ..."),
    grantRoles,
    () => console.log("Roles Granted ..."),
    setupSchedule,
    () => console.log("Schedule setted up ..."),
    citadelMinterSetup,
    () => console.log("Citadel minter setup ..."),
    setDiscount,
    () => console.log("Discount setted ..."),
    bondTokenForXCTDL,
    () => console.log("bond some WBTC and CVX to get xCTDL ..."),
    addOracleProviders,
    () => console.log("Add oracle Provider"),
    xCTDLVesting,
    () => console.log("xCTDL vesting"),
    setupKnightingRound,
    () => console.log("Knighting round setup")
  );
};

module.exports = deployLocal;
