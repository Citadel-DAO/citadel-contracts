const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const path = require("path");

const pipeActions = require("../utils/pipeActions");
const initializer = require("./initializer");
const setupLibraries = require("./setupLibraries");
const setupAndDeploy = require("./setupAndDeploy");
const mockMint = require("./mockMint");
const grantRoles = require("./grantRoles");
const storeConfigs = require("./storeConfig");
const getRoleSigners = require("./getRoleSingers");

const setXCitadelStrategy = require("./setXCitadelStrategy");
const citadelMinterSetup = require("./citadelMinterSetup");
const approveFundingTokens = require("./approveFundingTokens");
const medianOracleUpdatePrice = require("./medianOracleUpdatePrice");
const setDiscount = require("./setDiscount");
const bondTokenForXCTDL = require("./bondTokenForXCTDL");
const xCTDLVesting = require("./xCTDLVesting");
const setupKnightingRound = require("./setupKnightingRound");
const setupSchedule = require("./setupSchedule");

const deployWithMock = async () => {
  const signers = await ethers.getSigners();

  const mintTo = signers[0].address;
  const xCitadelFees = [0, 0, 0, 0];
  const user = signers[0];
  const multisig = signers[2];

  const basePath = path.join(__dirname, "..", "..", "scripts-data");
  const configFile = `${hre.network.name}-mock-config`;

  const deployer = new ethers.Wallet(
    "b2110be34ab23a080c865273ef5ec58f16d58b3b4ddf23f4bb7054984aeea286",
    ethers.provider
  );

  // Send 1 ether to an ens name.
  await signers[19].sendTransaction({
    to: deployer.address,
    value: ethers.utils.parseEther("1.0"),
  });

  await pipeActions({
    xCitadelFees,
    mintTo,
    basePath,
    configFile,
    user,
    multisig,
    deployer,
  })(
    setupLibraries,
    () => console.log("Setting up libraries ..."),
    setupAndDeploy,
    () => console.log("Contracts setted up ..."),
    mockMint,
    () => console.log("Mock mints ready ..."),
    getRoleSigners,
    () => console.log("Roles assigned ..."),
    initializer,
    () => console.log("Contracts initialized ..."),
    setXCitadelStrategy,
    () => console.log("Setted xCitadel strategy  ..."),
    grantRoles,
    () => console.log("Roles Granted ..."),
    setupSchedule,
    () => console.log("Schedule setted up ..."),
    citadelMinterSetup,
    () => console.log("Citadel minter setup ..."),
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
    //storeConfigs,
    //() => console.log("Config stored ...")
  );
};

module.exports = deployWithMock;
