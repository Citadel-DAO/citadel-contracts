const hre = require("hardhat");
const ethers = hre.ethers;
const getContractFactories = require("./getContractFactories");
const deployContracts = require("./deployContracts");

const mockMint = (mintTo) => async () => {
  const { wBTC, CVX, USDC } = await getContractFactories();

  const { wbtc, cvx, usdc } = await deployContracts([
    { factory: wBTC, instance: "wbtc" },
    { factory: CVX, instance: "cvx" },
    { factory: USDC, instance: "usdc" },
  ]);

  await wbtc.mint(mintTo, ethers.BigNumber.from("100000000"));
  await cvx.mint(mintTo, ethers.constants.WeiPerEther);
  await usdc.mint(mintTo, ethers.BigNumber.from("100000000000"));

  return {
    wBTC,
    CVX,
    USDC,
    wbtc,
    cvx,
    usdc,
  };
};

module.exports = mockMint;
