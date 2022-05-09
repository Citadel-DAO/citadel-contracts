const hre = require("hardhat");
const ethers = hre.ethers;
const moment = require("moment");
const {
  calcTokenOutPerTokenIn,
  getTokensPrices,
} = require("./utils/getTokensPrice");
const getContractFactories = require("./utils/getContractFactories");
const { address, hashIt } = require("./utils/helpers");

/// THIS SCRIPT MUST BE RUN WITH A FORKNET OR MAINNET
/// IT DOES NOT WORK OTHERWISE

async function main() {
  const signers = await ethers.getSigners();

  const initialParams = {
    citadelTokenAddress: "0xE8addD62feD354203d079926a8e563BC1A7FE81e", // Change this with your own deployed citadel token address
    citadelMultising: signers[2].address, // ATTENTION!!!! CHANGE THIS!!!!!!!!
  };

  const { GlobalAccessControl, KnightingRoundGuestlist, KnightingRound } =
    await getContractFactories();

  // Adding 180 second to not be in past
  // if you got this "KnightingRound: start date may not be in the past"
  // please increase this variable
  const additionalSeconds = 180;
  const phase1Start = parseInt(
    moment().add(additionalSeconds, "seconds").unix()
  );
  const phase2Start = parseInt(
    moment().add(additionalSeconds, "seconds").add(3, "days").unix()
  );

  const phase1Duration = 3 * 24 * 3600;
  const phase2Duration = 2 * 24 * 3600;

  const phase1UsdLimit = ethers.constants.MaxUint256;
  const phase2UsdLimit = ethers.BigNumber.from(1 * 10 ** 6);

  const governance = signers[12];
  const techOp = signers[13];

  const gac = await GlobalAccessControl.deploy();
  await gac.connect(governance).initialize(governance.address);
  await gac
    .connect(governance)
    .grantRole(hashIt("TECH_OPERATIONS_ROLE"), address(techOp));

  const tokenInsPhase1 = [
    {
      name: "wBTC",
      address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
      decimals: 8,
    },
    {
      name: "renBTC",
      address: "0xeb4c2781e4eba804ce9a9803c67d0893436bb27d",
      decimals: 8,
    },
    {
      name: "ibBTC",
      address: "0xc4e15973e6ff2a35cc804c2cf9d2a1b817a8b40f",
      decimals: 18,
    },
    {
      name: "WETH",
      address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
      decimals: 18,
    },
    {
      name: "FRAX",
      address: "0x853d955acef822db058eb8505911ed77f175b99e",
      decimals: 18,
    },
    {
      name: "USDC",
      address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      decimals: 6,
    },
  ];

  const knightingRoundGuestList = await KnightingRoundGuestlist.deploy();

  await knightingRoundGuestList.initialize(address(gac));

  const guestListRoot =
    "0x7e5eaba80a7bd7636e9edd5c7a84daa71b476e698bb85f06202152751fb9b5f8";

  await knightingRoundGuestList.connect(techOp).setGuestRoot(guestListRoot);

  const tokensPrices = await getTokensPrices(
    tokenInsPhase1.map((tk) => tk.address)
  );

  const desiredPriceInUsd = 21;

  const readyTokensListPhase1 = tokenInsPhase1.map((tk) => ({
    ...tk,
    usdPrice: tokensPrices[tk.address].usd,
    tokenOutPerTokenIn: calcTokenOutPerTokenIn(
      desiredPriceInUsd,
      tokensPrices[tk.address].usd,
      tk.decimals
    ),
  }));

  // Deploy knighting rounds for each token one at a time
  console.log("Phase 1: ==================================");
  const deployKnightingRoundPhase1 = async (i = 0) => {
    const currentToken = readyTokensListPhase1[i];
    if (!currentToken) return;
    const knightingRound = await KnightingRound.deploy();

    console.log(
      `${currentToken.name} knighting round addres: `,
      knightingRound.address
    );

    await knightingRound.initialize(
      address(gac),
      initialParams.citadelTokenAddress,
      currentToken.address,
      phase1Start,
      phase1Duration,
      currentToken.tokenOutPerTokenIn,
      initialParams.citadelMultising,
      address(knightingRoundGuestList),
      phase1UsdLimit
    );

    return await deployKnightingRoundPhase1(i + 1);
  };

  await deployKnightingRoundPhase1();

  console.log("Phase 2: ==================================");

  const tokenInsPhase2 = [
    {
      name: "Badger",
      address: "0x3472a5a71965499acd81997a54bba8d852c6e53d",
      decimals: 18,
    },
    {
      name: "CVX",
      address: "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b",
      decimals: 18,
    },
    {
      name: "bveCVX",
      address: "0xfd05D3C7fe2924020620A8bE4961bBaA747e6305",
      decimals: 18,
    },
  ];

  const tokens2Prices = await getTokensPrices(
    tokenInsPhase2.map((tk) => tk.address)
  );

  const readyTokensListPhase2 = tokenInsPhase2.map((tk) => ({
    ...tk,
    usdPrice: tokens2Prices[tk.address]
      ? tokens2Prices[tk.address].usd
      : tokens2Prices["0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b"].usd,
    tokenOutPerTokenIn: calcTokenOutPerTokenIn(
      desiredPriceInUsd,
      tokens2Prices[tk.address]
        ? tokens2Prices[tk.address].usd
        : tokens2Prices["0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b"].usd,
      tk.decimals
    ),
  }));

  const deployKnightingRoundPhase2 = async (i = 0) => {
    const currentToken = readyTokensListPhase2[i];
    if (!currentToken) return;
    const knightingRound = await KnightingRound.deploy();

    console.log(
      `${currentToken.name} knighting round addres: `,
      knightingRound.address
    );

    await knightingRound.initialize(
      address(gac),
      initialParams.citadelTokenAddress,
      currentToken.address,
      phase2Start,
      phase2Duration,
      currentToken.tokenOutPerTokenIn,
      initialParams.citadelMultising,
      address(knightingRoundGuestList),
      phase2UsdLimit
        .mul(
          ethers.BigNumber.from(10).pow(
            ethers.BigNumber.from(currentToken.decimals + 8)
          )
        )
        .div(ethers.BigNumber.from(parseInt(currentToken.usdPrice * 10 ** 8)))
    );

    return await deployKnightingRoundPhase2(i + 1);
  };

  await deployKnightingRoundPhase2();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
