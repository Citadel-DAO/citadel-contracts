const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const path = require("path");

const pipeActions = require("../utils/pipeActions");
const initializer = require("./initializer");
const setupAndDeploy = require("./setupAndDeploy");
const mockMint = require("./mockMint");
const grantRoles = require("./grantRoles");
const storeConfigs = require("./storeConfig");
const getRoleSigners = require("./getRoleSingers");

const deployWithMock = async () => {
  const signers = await ethers.getSigners();

  const mintTo = signers[0].address;
  const xCitadelFees = [0, 0, 0, 0];

  const basePath = path.join(__dirname, "..", "..", "scripts-data");
  const configFile = `${hre.network.name}-mock-config`;

  await pipeActions({ xCitadelFees, mintTo, basePath, configFile })(
    setupAndDeploy,
    () => console.log("Contracts setted up ..."),
    mockMint,
    () => console.log("Mock mints ready ..."),
    getRoleSigners,
    () => console.log("Roles assigned ..."),
    initializer,
    () => console.log("Contracts initialized ..."),
    grantRoles,
    () => console.log("Roles Granted ..."),
    storeConfigs,
    () => console.log("Config stored ...")
  );
};

module.exports = deployWithMock;
