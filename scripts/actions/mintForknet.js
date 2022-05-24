const hre = require("hardhat");
const ethers = hre.ethers;
const { formatUnits, parseUnits } = ethers.utils;
const { address } = require("../utils/helpers");

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";

const wbtc_minter_address = "0xCA06411bd7a7296d7dbdd0050DFc846E95fEBEB7"; // owner address of wbtc
const cvx_minter_address = "0xF403C135812408BFbE8713b5A23a04b3D48AAE31"; // operator address of cvx

const erc20_mintable_abi = ["function mint(address, uint256)"];

const mintForknet = async ({ mintTo, ERC20Upgradeable }) => {
  /// === mint wbtc and cvx to signers[0]
  // impersonate the token owner
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [wbtc_minter_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [cvx_minter_address],
  });

  // send some balance for the gas
  await hre.network.provider.send("hardhat_setBalance", [
    wbtc_minter_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    cvx_minter_address,
    "0x1000000000000000000",
  ]);

  // get the signer
  const wbtc_minter = await ethers.getSigner(wbtc_minter_address);
  const cvx_minter = await ethers.getSigner(cvx_minter_address);

  // connect the token contract to signers
  const wbtcMintable = new ethers.Contract(
    wbtc_address,
    erc20_mintable_abi,
    wbtc_minter
  );

  const cvxMintable = new ethers.Contract(
    cvx_address,
    erc20_mintable_abi,
    cvx_minter
  );

  // mint some tokens to signers[0]
  const user = mintTo;
  const txWbtcMint = await wbtcMintable.mint(
    address(user),
    parseUnits("100", 8) // 100 btc
  );
  await txWbtcMint.wait();
  await cvxMintable.mint(
    address(user),
    parseUnits("100000", 18) // 100000 cvx
  );

  const wbtc = ERC20Upgradeable.attach(wbtc_address);
  console.log(`wbtc address is: ${wbtc.address}`);
  const cvx = ERC20Upgradeable.attach(cvx_address);
  console.log(`cvx address is: ${cvx.address}`);
  const usdc = ERC20Upgradeable.attach("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48");
  console.log(`usdc address is: ${usdc.address}`);
  const renBTC = ERC20Upgradeable.attach("0xeb4c2781e4eba804ce9a9803c67d0893436bb27d");
  console.log(`renBTC address is: ${renBTC.address}`);
  const ibBTC = ERC20Upgradeable.attach("0xc4e15973e6ff2a35cc804c2cf9d2a1b817a8b40f");
  console.log(`ibBTC address is: ${ibBTC.address}`);
  const wETH = ERC20Upgradeable.attach("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2");
  console.log(`wETH address is: ${wETH.address}`);
  const frax = ERC20Upgradeable.attach("0x853d955acef822db058eb8505911ed77f175b99e");
  console.log(`frax address is: ${frax.address}`);
  const badger = ERC20Upgradeable.attach("0x3472a5a71965499acd81997a54bba8d852c6e53d");
  console.log(`badger address is: ${badger.address}`);
  const bveCVX = ERC20Upgradeable.attach("0xfd05D3C7fe2924020620A8bE4961bBaA747e6305");
  console.log(`bveCVX address is: ${badger.address}`);

  // check the balance
  const balance_wbtc = await wbtc.balanceOf(address(user));
  console.log(`wbtc balance of signers[0]: ${formatUnits(balance_wbtc, 8)}`);
  const balance_cvx = await cvx.balanceOf(address(user));
  console.log(`cvx balance of signers[0]: ${formatUnits(balance_cvx, 18)}`);

  return {
    wbtc_minter,
    cvx_minter,
    wbtcMintable,
    cvxMintable,
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

module.exports = mintForknet;
