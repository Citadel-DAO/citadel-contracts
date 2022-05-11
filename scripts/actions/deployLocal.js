const hre = require("hardhat");
const ethers = hre.ethers;

const pipeActions = require("../utils/pipeActions");
const setupAndDeploy = require("./setupAndDeploy");
const mintForknet = require("./mintForknet");

const deployLocal = async () => {
  const signers = await ethers.getSigners();

  const mintTo = signers[0];

  await pipeActions({ mintTo })(
    setupAndDeploy,
    () => console.log("Contracts setted up ..."),
    mintForknet,
    () => console.log("Forknet mints ...")
  );
};

module.exports = deployLocal;
