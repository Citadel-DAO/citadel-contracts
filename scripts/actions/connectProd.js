const hre = require("hardhat");
const ethers = hre.ethers;

const pipeActions = require("../utils/pipeActions");
const prodDeploy = require("./prodDeploy");
const mintForknet = require("./mintForknet");
const getRoleSigners = require("./prod/getRoleSingers");
const initializer = require("./initializer");
const grantRoles = require("./grantRoles");
const setXCitadelStrategy = require("./setXCitadelStrategy");
const citadelMinterSetup = require("./citadelMinterSetup");
const approveFundingTokens = require("./approveFundingTokens");
const medianOracleUpdatePrice = require("./medianOracleUpdatePrice");
const setDiscount = require("./setDiscount");
const bondTokenForXCTDL = require("./bondTokenForXCTDL");
const xCTDLVesting = require("./xCTDLVesting");
const setupKnightingRound = require("./setupKnightingRound");
const setupSchedule = require('./setupSchedule')
const getContractFactories = require("./getContractFactories");

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";

const wbtc_minter_address = "0xCA06411bd7a7296d7dbdd0050DFc846E95fEBEB7"; // owner address of wbtc
const cvx_minter_address = "0xF403C135812408BFbE8713b5A23a04b3D48AAE31"; // operator address of cvx

const erc20_mintable_abi = ["function mint(address, uint256)"];

const { feeds,
  multisigs,
  logics,
  proxies } = require('../deploys')

const verify = async (toVerify) => {
  // Add Logic Addresses

  console.log("Verifying " + toVerify + " ...");
  await hre.run("verify:verify", {
    address: toVerify,
    constructorArguments: [],
  });
}

// TODO: Please set this as an env variable to read
// Note that this is the PK to the well-known hardhat node account #1 and will lose all assets if sent
const DEPLOYER_PRIVATE_KEY = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d" 

const connectProd = async () => {
  const deployer = new ethers.Wallet(DEPLOYER_PRIVATE_KEY, ethers.provider)

  const {
    GlobalAccessControl,
    CitadelToken,
    StakedCitadelVester,
    StakedCitadel,
    StakedCitadelLocker,
    SupplySchedule,
    CitadelMinter,
    KnightingRound,
    Funding,
    ERC20Upgradeable,
    MedianOracle,
    TransparentUpgradeableProxy
  } = await getContractFactories();

  const gac = GlobalAccessControl.attach(proxies.gac)
  console.log("gac: ", gac.address);

  const citadel = CitadelToken.attach(proxies.citadel)
  console.log("citadel: ", citadel.address);

  const xCitadel = StakedCitadel.attach(proxies.xCitadel)
  console.log("xCitadel: ", xCitadel.address);

  const xCitadelVester = StakedCitadelVester.attach(proxies.xCitadelVester)
  console.log("xCitadelVester: ", xCitadelVester.address);

  const xCitadelLocker = StakedCitadelVester.attach(proxies.xCitadelLocker)
  console.log("xCitadelLocker: ", xCitadelVester.address);

  const schedule = SupplySchedule.attach(proxies.schedule)
  console.log("schedule: ", schedule.address);

  const citadelMinter = CitadelMinter.attach(proxies.citadelMinter)
  console.log("citadelMinter: ", citadelMinter.address);

  const wbtc = ERC20Upgradeable.attach(wbtc_address);
  console.log(`wbtc address is: ${wbtc.address}`);
  const cvx = ERC20Upgradeable.attach(cvx_address);
  console.log(`cvx address is: ${cvx.address}`);
  const usdc = ERC20Upgradeable.attach("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48");
  console.log(`usdc address is: ${usdc.address}`);
  const renBTC = ERC20Upgradeable.attach("0xeb4c2781e4eba804ce9a9803c67d0893436bb27d");
  console.log(`renBTC address is: ${renBTC.address}`);
  const ibBTCLP = ERC20Upgradeable.attach("0xaE96fF08771a109dc6650a1BdCa62F2d558E40af");
  console.log(`ibBTCLP address is: ${ibBTCLP.address}`);
  const wETH = ERC20Upgradeable.attach("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2");
  console.log(`wETH address is: ${wETH.address}`);
  const frax = ERC20Upgradeable.attach("0x853d955acef822db058eb8505911ed77f175b99e");
  console.log(`frax address is: ${frax.address}`);
  const badger = ERC20Upgradeable.attach("0x3472a5a71965499acd81997a54bba8d852c6e53d");
  console.log(`badger address is: ${badger.address}`);
  const bveCVX = ERC20Upgradeable.attach("0xfd05D3C7fe2924020620A8bE4961bBaA747e6305");
  console.log(`bveCVX address is: ${bveCVX.address}`);

  // How to verify a contract on etherscan
  // await verify("0xd03A04901041ac9313E83C47B23e9ACD1b1E12eE")

};

module.exports = connectProd;
