const hre = require("hardhat");

const ethers = hre.ethers;

const setupLibraries = async ({ deployer }) => {
  const KnightingRoundData = await ethers.getContractFactory(
    "KnightingRoundData"
  );

  const knightingRoundData = await KnightingRoundData.connect(
    deployer
  ).deploy();

  return {
    knightingRoundData,
  };
};

module.exports = setupLibraries;
