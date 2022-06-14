const hre = require("hardhat");
const ethers = hre.ethers;
const { address } = require("../utils/helpers");

const { formatUnits, parseUnits } = ethers.utils;

const FundingBonder = require("./FundingBonder");

const { getTokensPrices } = require("../utils/getTokensPrice");

const feeds = {
  CTDL_WBTC_CURVE_POOL: "0x50f3752289e1456bfa505afd37b241bca23e685d",
  WBTC_BTC_PRICE_FEED: "0xfdfd9c85ad200c506cf9e21f1fd8dd01932fbb23",
  BTC_ETH_PRICE_FEED: "0xdeb288f737066589598e9214e782fa5a8ed689e8",
  BTC_USD_PRICE_FEED: "0xf4030086522a5beea4988f8ca5b36dbc97bee88c",
  ETH_USD_PRICE_FEED: "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419",
  WIBBTC_LP_VAULT: "0xae96ff08771a109dc6650a1bdca62f2d558e40af",
  FRAX_ETH_PRICE_FEED: "0x14d04fff8d21bd62987a5ce9ce543d2f1edf5d3e",
  FRAX_USD_PRICE_FEED: "0xb9e1e3a9feff48998e45fa90847ed4d467e8bcfd",
  USDC_ETH_PRICE_FEED: "0x986b5e1e1755e3c2440e960477f25201b0a8bbd4",
  USDC_USD_PRICE_FEED: "0x8fffffd4afb6115b954bd326cbe7b4ba576818f6",
  CVX_ETH_PRICE_FEED: "0xc9cbf687f43176b302f03f5e58470b77d07c61c6",
  CVX_USD_PRICE_FEED: "0xd962fc30a72a84ce50161031391756bf2876af5d",
  BADGER_ETH_PRICE_FEED: "0x58921ac140522867bf50b9e009599da0ca4a2379",
  BADGER_USD_PRICE_FEED: "0x66a47b7206130e6ff64854ef0e1edfa237e65339",
};

const bondTokenForXCTDL = async ({
  fundingWbtc,
  fundingCvx,
  user,
  xCitadel,
  wbtc,
  cvx,
  apeCvxAmount,
  apeWbtcAmount,
  apeGeneral,
  fundingRegistry,
  Funding,
  ERC20Upgradeable,
  keeper,
  MedianOracle,
  tokenIns,
}) => {
  // bond some WBTC and CVX to get xCTDL

  const fundingBonder = FundingBonder({ user, slippage: 0 });

  const fundingsList = await fundingRegistry.getAllFundings();

  const targetProvider = "0xA967Ba66Fb284EC18bbe59f65bcf42dD11BA8128";

  const provider = await ethers.getSigner(targetProvider);

  const allFundingsBonder = async (i = 0) => {
    const currentFunding = fundingsList[i]
      ? Funding.attach(fundingsList[i])
      : undefined;
    if (!currentFunding) return;

    const asset = ERC20Upgradeable.attach(await currentFunding.asset());

    const tokensPrices = await getTokensPrices(
      tokenIns.map((token) => token.priceAddress)
    );
    const targetPrice = 21;

    const assetAddress = await currentFunding.asset();

    const initFundPriceAsset = tokenIns.find(
      (tI) => tI.address.toLowerCase() === assetAddress.toLowerCase()
    ).priceAddress;

    const priceToReport = parseUnits(
      String(tokensPrices[initFundPriceAsset].usd / targetPrice),
      18
    );

    const oracleAddress = await currentFunding.citadelPerAssetOracle();

    const currentOracle = await MedianOracle.attach(oracleAddress);

    await currentOracle.connect(provider).pushReport(priceToReport);

    //  console.log("Oracle Address: ", currentOracle.address);
    //  console.log(await currentOracle.callStatic.getData());

    await currentFunding.connect(keeper).updateCitadelPerAsset();

    //console.log("?????");

    await fundingBonder({
      funding: currentFunding,
      amount: apeGeneral,
      token: asset,
    });

    return await allFundingsBonder(i + 1);
  };

  await allFundingsBonder();

  console.log(
    `balance of xCTDL after  deposits: ${formatUnits(
      await xCitadel.balanceOf(address(user)),
      18
    )}`
  );

  return {
    apeWbtcAmount,
    apeCvxAmount,
  };
};

module.exports = bondTokenForXCTDL;
