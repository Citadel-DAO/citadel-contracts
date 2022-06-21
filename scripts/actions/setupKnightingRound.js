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
  deployer,
  tokenIns,
  knightingRoundRegistry,
}) => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);

  const { KnightingRoundGuestlist, KnightingRoundWithEth, KnightingRound } =
    await getContractFactories({});

  const additionalSeconds = 90;

  const startTime = blockBefore.timestamp + additionalSeconds;

  const duration = 3 * 24 * 3600;

  const knightingRoundGuestList = await KnightingRoundGuestlist.deploy();

  await knightingRoundGuestList.initialize(address(gac));

  const guestListRoot =
    "0xe38ffd36a38714c34e25025c3338c7c0d1f0c022ca20f62aba3332683483c9fd";

  await knightingRoundGuestList.connect(techOps).setGuestRoot(guestListRoot);

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
    const knightingRound = await KnightingRound.connect(deployer).deploy();

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

  //await deployKnightinRounds();

  const knightingRoundImplementation = await KnightingRound.connect(
    deployer
  ).deploy();
  const knightingRoundWithEthImplementation =
    await KnightingRoundWithEth.connect(deployer).deploy();

  const wethParams = readyTokensList
    .filter((token) => token.name == "WETH")
    .map((token) => [
      token.address,
      phase1UsdLimit,
      token.tokenOutPerTokenIn,
    ])[0];
  const roundsParams = readyTokensList
    .filter((token) => token.name !== "WETH")
    .map((token) => [token.address, phase1UsdLimit, token.tokenOutPerTokenIn]);

  await knightingRoundRegistry.initialize(
    address(knightingRoundImplementation),
    address(knightingRoundWithEthImplementation),
    KnightingRound.interface.getSighash("initialize"),
    address(gac),
    startTime,
    duration,
    address(citadel),
    address(multisig),
    address(knightingRoundGuestList),
    wethParams,
    roundsParams
  );

  const roundsData = await knightingRoundRegistry.getAllRoundsData();

  roundsData.forEach((roundData, i) => {
    if (i === roundsData.length - 1) {
      console.log(`Knighting round with eth addres: `, roundData.roundAddress);
    } else {
      console.log(
        `${
          tokenIns.find(
            (tok) =>
              tok.address.toLowerCase() === roundData.tokenIn.toLowerCase()
          ).name
        } knighting round addres: `,
        roundData.roundAddress
      );
    }
  });
};

module.exports = setupKnightingRound;
