const hre = require("hardhat");
const ethers = hre.ethers;

const getContractFactories = require("./getContractFactories");
const {
  calcTokenOutPerTokenIn,
  getTokensPrices,
} = require("../utils/getTokensPrice");
const { address } = require("../utils/helpers");

const setupKnightingRound = async ({
  gac,
  multisig,
  citadel,
  techOps,
  wbtc,
  cvx,
  usdc,
  renBTC,
  ibBTC,
  wETH,
  frax,
  badger,
}) => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);

  const { KnightingRoundGuestlist, KnightingRound } =
    await getContractFactories();

  const additionalSeconds = 90;

  const startTime = blockBefore.timestamp + additionalSeconds;

  const duration = 3 * 24 * 3600;

  const knightingRoundGuestList = await KnightingRoundGuestlist.deploy();

  await knightingRoundGuestList.initialize(address(gac));

  const guestListRoot =
    "0x8916c3fedd925241fcbba35af8d2380b5658ad8fa17e1b525bb1851107a36b35";

  await knightingRoundGuestList.connect(techOps).setGuestRoot(guestListRoot);

  const tokenIns = [
    {
      name: "wBTC",
      priceAddress: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
      address: address(wbtc),
      decimals: 8,
    },
    {
      name: "renBTC",
      priceAddress: "0xeb4c2781e4eba804ce9a9803c67d0893436bb27d",
      address: address(renBTC),
      decimals: 8,
    },
    {
      name: "ibBTC",
      priceAddress: "0xc4e15973e6ff2a35cc804c2cf9d2a1b817a8b40f",
      address: address(ibBTC),
      decimals: 18,
    },
    {
      name: "WETH",
      priceAddress: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
      address: address(wETH),
      decimals: 18,
    },
    {
      name: "FRAX",
      priceAddress: "0x853d955acef822db058eb8505911ed77f175b99e",
      address: address(frax),
      decimals: 18,
    },
    {
      name: "USDC",
      priceAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      address: address(usdc),
      decimals: 6,
    },
    {
      name: "Badger",
      priceAddress: "0x3472a5a71965499acd81997a54bba8d852c6e53d",
      address: address(badger),
      decimals: 18,
    },
    {
      name: "CVX",
      priceAddress: "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b",
      address: address(cvx),
      decimals: 18,
    },
  ];

  const tokensPrices = await getTokensPrices(
    tokenIns.map((tk) => tk.priceAddress)
  );

  const desiredPriceInUsd = 21;

  const phase1UsdLimit = ethers.constants.MaxUint256;

  const readyTokensList = tokenIns.map((tk) => ({
    ...tk,
    usdPrice: tokensPrices[tk.priceAddress].usd,
    tokenOutPerTokenIn: calcTokenOutPerTokenIn(
      desiredPriceInUsd,
      tokensPrices[tk.priceAddress].usd,
      tk.decimals
    ),
  }));

  // Deploy knighting rounds for each token one at a time
  console.log("Knighting Rounds: ==================================");
  const deployKnightinRounds = async (i = 0) => {
    const currentToken = readyTokensList[i];
    if (!currentToken) return;
    console.log(currentToken);
    const knightingRound = await KnightingRound.deploy();

    console.log(
      `${currentToken.name} knighting round addres: `,
      knightingRound.address
    );

    await knightingRound.initialize(
      address(gac),
      address(citadel),
      currentToken.address,
      startTime,
      duration,
      currentToken.tokenOutPerTokenIn,
      address(multisig),
      address(knightingRoundGuestList),
      phase1UsdLimit
    );

    return await deployKnightinRounds(i + 1);
  };

  await deployKnightinRounds();
};

module.exports = setupKnightingRound;
