const hre = require("hardhat");
const ethers = hre.ethers;
const getContractFactories = require("./getContractFactories");
const deployContracts = require("./deployContracts");
const { address } = require("../utils/helpers");
const { formatUnits, parseUnits } = ethers.utils;

const mockMint = async ({ user, deployer }) => {
  const { wBTC, CVX, USDC, MintableToken } = await getContractFactories({});

  const { wbtc, cvx, usdc } = await deployContracts(deployer)([
    { factory: wBTC, instance: "wbtc" },
    { factory: CVX, instance: "cvx" },
    { factory: USDC, instance: "usdc" },
  ]);

  const renBTC = await MintableToken.connect(deployer).deploy("renBTC", "rentBTC");
  console.log(`renBTC address is: ${renBTC.address}`);
  const ibBTC = await MintableToken.connect(deployer).deploy("ibBTC", "ibBTC");
  console.log(`ibBTC address is: ${ibBTC.address}`);
  const wETH = await MintableToken.connect(deployer).deploy("wETH", "wETH");
  console.log(`wETH address is: ${wETH.address}`);
  const frax = await MintableToken.connect(deployer).deploy("frax", "frax");
  console.log(`frax address is: ${frax.address}`);
  const badger = await MintableToken.connect(deployer).deploy("badger", "badger");
  console.log(`badger address is: ${badger.address}`);
  const bveCVX = await MintableToken.connect(deployer).deploy("bveCVX", "bveCVX");
  console.log(`badger address is: ${badger.address}`);

  await wbtc.mint(address(user), parseUnits("2000000000",18));
  await cvx.mint(address(user), parseUnits("10000000000", 18));
  await usdc.mint(address(user), parseUnits("10000000000", 18));

  await renBTC.mint(address(user), parseUnits("10000000000", 18));
  await ibBTC.mint(address(user), parseUnits("10000000000", 18));

  await wETH.mint(address(user), parseUnits("10000000000", 18));
  await frax.mint(address(user), parseUnits("10000000000", 18));
  await badger.mint(address(user), parseUnits("10000000000", 18));
  await bveCVX.mint(address(user), parseUnits("10000000000", 18));

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
    bveCVX
  };
};

module.exports = mockMint;
