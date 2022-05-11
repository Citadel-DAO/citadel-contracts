const hre = require("hardhat");
const ethers = hre.ethers;

const changeBlockTimestamp = async (changeTime) => {
  await hre.network.provider.send("evm_setNextBlockTimestamp", [changeTime]);
  await hre.network.provider.send("evm_mine");
};

module.exports = changeBlockTimestamp;
