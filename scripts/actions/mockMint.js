const hre = require("hardhat");
const ethers = hre.ethers;
const getContractFactories = require("./getContractFactories");
const deployContracts = require("./deployContracts");
const { address } = require("../utils/helpers");
const { formatUnits, parseUnits } = ethers.utils;

const mockMint = async ({ user }) => {
  const { wBTC, CVX, USDC, MintableToken } = await getContractFactories();

  const { wbtc, cvx, usdc } = await deployContracts([
    { factory: wBTC, instance: "wbtc" },
    { factory: CVX, instance: "cvx" },
    { factory: USDC, instance: "usdc" },
  ]);

  const renBTC = await MintableToken.deploy("renBTC", "rentBTC");
  console.log(`renBTC address is: ${renBTC.address}`);
  const ibBTC = await MintableToken.deploy("ibBTC", "ibBTC");
  console.log(`ibBTC address is: ${ibBTC.address}`);
  const wETH = await MintableToken.deploy("wETH", "wETH");
  console.log(`wETH address is: ${wETH.address}`);
  const frax = await MintableToken.deploy("frax", "frax");
  console.log(`frax address is: ${frax.address}`);
  const badger = await MintableToken.deploy("badger", "badger");
  console.log(`badger address is: ${badger.address}`);

  await wbtc.mint(address(user), parseUnits("20", 8));
  await cvx.mint(address(user), parseUnits("100000", 18));
  await usdc.mint(address(user), parseUnits("100000", 18));

  await renBTC.mint(address(user), parseUnits("100000", 18));
  await ibBTC.mint(address(user), parseUnits("100000", 18));

  await wETH.mint(address(user), parseUnits("100000", 18));
  await frax.mint(address(user), parseUnits("100000", 18));
  await badger.mint(address(user), parseUnits("100000", 18));

  return {
    wBTC,
    CVX,
    USDC,
    wbtc,
    cvx,
    usdc,
    renBTC,
    ibBTC,
    wETH,
    frax,
    badger,
  };
};

module.exports = mockMint;
