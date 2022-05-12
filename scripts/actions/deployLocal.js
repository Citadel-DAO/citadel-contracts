const hre = require("hardhat");
const ethers = hre.ethers;

const pipeActions = require("../utils/pipeActions");
const setupAndDeploy = require("./setupAndDeploy");
const mintForknet = require("./mintForknet");
const getRoleSigners = require("./getRoleSingers");
const initializer = require("./initializer");
const grantRoles = require("./grantRoles");
const setXCitadelStrategy = require("./setXCitadelStrategy");
const citadelMinterSetup = require("./citadelMinterSetup");
const approveFundingTokens = require("./approveFundingTokens");
const medianOracleUpdatePrice = require("./medianOracleUpdatePrice");
const setDiscount = require("./setDiscount");
const bondTokenForXCTDL = require("./bondTokenForXCTDL");
const xCTDLVesting = require("./xCTDLVesting");

const setupKnightingRound = require("./setupKnightingRound");

const deployLocal = async () => {
  const signers = await ethers.getSigners();

  const user = signers[0];
  const mintTo = signers[0];
  const xCitadelFees = [0, 0, 0, 0];
  const multisig = signers[2];

  await pipeActions({ mintTo, xCitadelFees, user, multisig })(
    setupAndDeploy,
    () => console.log("Contracts setted up ..."),
    mintForknet,
    () => console.log("Forknet mints ..."),
    getRoleSigners,
    () => console.log("Roles assigned ..."),
    initializer,
    () => console.log("Contracts initialized ..."),
    setXCitadelStrategy,
    () => console.log("Setted xCitadel strategy  ..."),
    grantRoles,
    () => console.log("Roles Granted ..."),
    citadelMinterSetup,
    () => console.log("Citadel minter setup ..."),
    approveFundingTokens,
    () => console.log("Funding tokens approved ..."),
    medianOracleUpdatePrice,
    () => console.log("Median oracle update the price ..."),
    setDiscount,
    () => console.log("Discount setted ..."),
    bondTokenForXCTDL,
    () => console.log("bond some WBTC and CVX to get xCTDL ..."),
    xCTDLVesting,
    () => console.log("xCTDL vesting"),
    setupKnightingRound,
    () => console.log("Knighting round setup")
  );
};

module.exports = deployLocal;
