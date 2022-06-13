const hre = require("hardhat");
const ethers = hre.ethers;
const { formatUnits, parseUnits } = ethers.utils;
const { address } = require("../utils/helpers");

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";
const renBTC_address = "0xeb4c2781e4eba804ce9a9803c67d0893436bb27d";
const usdc_address = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
const ibBTC_address = "0xc4e15973e6ff2a35cc804c2cf9d2a1b817a8b40f";
const weth_address = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const frax_address = "0x853d955acef822db058eb8505911ed77f175b99e";
const badger_address = "0x3472a5a71965499acd81997a54bba8d852c6e53d";
const bveCvx_address = "0xfd05D3C7fe2924020620A8bE4961bBaA747e6305";

const wbtc_minter_address = "0xCA06411bd7a7296d7dbdd0050DFc846E95fEBEB7"; // owner address of wbtc
const cvx_minter_address = "0xF403C135812408BFbE8713b5A23a04b3D48AAE31"; // operator address of cvx
const renBTC_minter_address = "0xe4b679400f0f267212d5d812b95f58c83243ee71";
const usdc_minter_address = "0x5b6122c109b78c6755486966148c1d70a50a47d7";
const ibBTC_whale_address = "0x511ed30e9404cbec4bb06280395b74da5f876d47";
const frax_whale_address = "0x93eddcd02cabf1002babeb4b6d28dbbf50e69b34";
const badger_whale_address = "0x36cc7b13029b5dee4034745fb4f24034f3f2ffc6";
const bveCvx_whale_address = "0x48d93dabf29aa5d86424a90ee60f419f1837649f";

const erc20_mintable_abi = ["function mint(address, uint256)"];
const weth_abi = [
  {
    constant: false,
    inputs: [],
    name: "deposit",
    outputs: [],
    payable: true,
    stateMutability: "payable",
    type: "function",
  },
];

const mintForknet = async ({ mintTo, ERC20Upgradeable, deployer }) => {
  const user = mintTo;
  /// === mint wbtc and cvx to signers[0]
  // impersonate the token owner
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [wbtc_minter_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [renBTC_minter_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [cvx_minter_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [usdc_minter_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [ibBTC_whale_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [frax_whale_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [badger_whale_address],
  });
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [bveCvx_whale_address],
  });

  // send some balance for the gas
  await hre.network.provider.send("hardhat_setBalance", [
    wbtc_minter_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    renBTC_minter_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    cvx_minter_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    usdc_minter_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    ibBTC_whale_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    mintTo.address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    frax_whale_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    badger_whale_address,
    "0x1000000000000000000",
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    bveCvx_address,
    "0x1000000000000000000",
  ]);

  // get the signer
  const wbtc_minter = await ethers.getSigner(wbtc_minter_address);
  const renBTC_minter = await ethers.getSigner(renBTC_minter_address);
  const cvx_minter = await ethers.getSigner(cvx_minter_address);
  const usdc_minter = await ethers.getSigner(usdc_minter_address);
  const ibBTC_whale = await ethers.getSigner(ibBTC_whale_address);
  const frax_whale = await ethers.getSigner(frax_whale_address);
  const badger_whale = await ethers.getSigner(badger_whale_address);
  const bveCvx_whale = await ethers.getSigner(bveCvx_whale_address);

  // connect the token contract to signers
  const wbtcMintable = new ethers.Contract(
    wbtc_address,
    erc20_mintable_abi,
    wbtc_minter
  );

  const renBTCMintable = new ethers.Contract(
    renBTC_address,
    erc20_mintable_abi,
    renBTC_minter
  );

  const cvxMintable = new ethers.Contract(
    cvx_address,
    erc20_mintable_abi,
    cvx_minter
  );

  const usdcMintable = new ethers.Contract(
    usdc_address,
    erc20_mintable_abi,
    usdc_minter
  );

  const ibBTCTransferable =
    ERC20Upgradeable.attach(ibBTC_address).connect(ibBTC_whale);

  const wethTransferable = new ethers.Contract(weth_address, weth_abi, user);

  const fraxTransferable =
    ERC20Upgradeable.attach(frax_address).connect(frax_whale);

  const badgerTransferable =
    ERC20Upgradeable.attach(badger_address).connect(badger_whale);

  const bveCvxTransferable =
    ERC20Upgradeable.attach(bveCvx_address).connect(bveCvx_whale);

  // mint some tokens to signers[0]
  const txWbtcMint = await wbtcMintable.mint(
    address(user),
    parseUnits("100", 8)
  );
  await txWbtcMint.wait();
  const txrenBtcMint = await renBTCMintable.mint(
    address(user),
    parseUnits("100", 8)
  );
  await txrenBtcMint.wait();
  const txcvxMint = await cvxMintable.mint(
    address(user),
    parseUnits("100000", 18)
  );
  await txcvxMint.wait();
  const txusdcMint = await usdcMintable.mint(
    address(user),
    parseUnits("100000", 6)
  );
  await txusdcMint.wait();
  const txIbtcTransfer = await ibBTCTransferable
    .connect(ibBTC_whale)
    .transfer(address(user), parseUnits("100", 16));
  await txIbtcTransfer.wait();
  await wethTransferable
    .connect(user)
    .deposit({ value: parseUnits("100", 18) });
  const txFraxTransfer = await fraxTransferable
    .connect(frax_whale)
    .transfer(address(user), parseUnits("1000", 18));
  await txFraxTransfer.wait();
  const txBadgerTransfer = await badgerTransferable
    .connect(badger_whale)
    .transfer(address(user), parseUnits("1000", 18));
  await txBadgerTransfer.wait();
  const txBvecvxTransfer = await bveCvxTransferable
    .connect(bveCvx_whale)
    .transfer(address(user), parseUnits("1000", 18));
  await txBvecvxTransfer.wait();

  const wbtc = ERC20Upgradeable.attach(wbtc_address);
  console.log(`wbtc address is: ${wbtc.address}`);
  const renBTC = ERC20Upgradeable.attach(renBTC_address);
  console.log(`renBTC address is: ${renBTC.address}`);

  const cvx = ERC20Upgradeable.attach(cvx_address);
  console.log(`cvx address is: ${cvx.address}`);
  const usdc = ERC20Upgradeable.attach(usdc_address);
  console.log(`usdc address is: ${usdc.address}`);

  const ibBTC = ERC20Upgradeable.attach(ibBTC_address);
  console.log(`ibBTC address is: ${ibBTC.address}`);
  const wETH = ERC20Upgradeable.attach(weth_address);
  console.log(`wETH address is: ${wETH.address}`);
  const frax = ERC20Upgradeable.attach(frax_address);
  console.log(`frax address is: ${frax.address}`);
  const badger = ERC20Upgradeable.attach(badger_address);
  console.log(`badger address is: ${badger.address}`);
  const bveCVX = ERC20Upgradeable.attach(bveCvx_address);
  console.log(`bveCVX address is: ${badger.address}`);

  // check the balance
  const balance_wbtc = await wbtc.balanceOf(address(user));
  console.log(`wbtc balance of signers[0]: ${formatUnits(balance_wbtc, 8)}`);
  const balance_cvx = await cvx.balanceOf(address(user));
  console.log(`cvx balance of signers[0]: ${formatUnits(balance_cvx, 18)}`);

  console.log(
    `frax balance of signers[0]: ${formatUnits(
      await frax.balanceOf(address(user)),
      18
    )}`
  );
  console.log(
    `badger balance of signers[0]: ${formatUnits(
      await badger.balanceOf(address(user)),
      18
    )}`
  );
  console.log(
    `bveCVX balance of signers[0]: ${formatUnits(
      await bveCVX.balanceOf(address(user)),
      18
    )}`
  );
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
    bveCVX,
  };
};

module.exports = mintForknet;
