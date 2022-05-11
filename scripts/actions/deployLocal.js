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

const deployLocal = async () => {
  const signers = await ethers.getSigners();

  const mintTo = signers[0];
  const xCitadelFees = [0, 0, 0, 0];

  await pipeActions({ mintTo, xCitadelFees })(
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
    () => console.log("Citadel minter setup ...")
  );
};

module.exports = deployLocal;
