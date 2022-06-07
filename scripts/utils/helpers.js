const hre = require("hardhat");
const ethers = hre.ethers;

const address = (entity) =>
  entity.address ? entity.address : ethers.constants.AddressZero;

const hashIt = (str) => ethers.utils.keccak256(ethers.utils.toUtf8Bytes(str));

const sleep = (ms) => {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = { address, hashIt, sleep };
