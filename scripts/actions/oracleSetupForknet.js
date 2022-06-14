const hre = require("hardhat");
const ethers = hre.ethers;
const { parseUnits } = ethers.utils;
const { getTokensPrices } = require("../utils/getTokensPrice");
const { address } = require("../utils/helpers");

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

const oracleSetupMock = async ({
  initFunds,
  keeper,
  tokenIns,
  Funding,
  CtdlWbtcCurveV2Provider,
  CtdlBtcChainlinkProvider,
  CtdlWibbtcLpVaultProvider,
  CtdlEthChainlinkProvider,
  CtdlAssetChainlinkProvider,
}) => {
  const targetProvider = "0xA967Ba66Fb284EC18bbe59f65bcf42dD11BA8128";

  const addOraclesProvider = async (i = 0) => {
    const currentOracle = initFunds[i]
      ? initFunds[i].citadelPerAssetOracle
      : undefined;
    if (!currentOracle) return;

    await currentOracle.addProvider(targetProvider);

    return await addOraclesProvider(i + 1);
  };

  addOraclesProvider();

  const tokensPrices = await getTokensPrices(
    tokenIns.map((token) => token.priceAddress)
  );
  const targetPrice = 21;

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [targetProvider],
  });

  await hre.network.provider.send("hardhat_setBalance", [
    targetProvider,
    "0x1000000000000000000",
  ]);

  const provider = await ethers.getSigner(targetProvider);

  const setPrice = async (i = 0) => {
    const currentOracle = initFunds[i]
      ? initFunds[i].citadelPerAssetOracle
      : undefined;
    if (!currentOracle || !initFunds[i]) return;

    const initFundPriceAsset = tokenIns.find(
      (tI) => tI.address == initFunds[i].asset
    ).priceAddress;

    const priceToReport = parseUnits(
      String(tokensPrices[initFundPriceAsset].usd / targetPrice),
      18
    );

    await currentOracle.connect(provider).pushReport(priceToReport);
    console.log("Oracle Address: ", currentOracle.address);
    console.log(await currentOracle.callStatic.getData());

    console.log("Pushing Price: ", priceToReport);

    return await setPrice(i + 1);
  };

  await setPrice();

 // const ctdlWbtcCurveV2Provider = await CtdlWbtcCurveV2Provider.deploy(
 //   feeds.CTDL_WBTC_CURVE_POOL
 // );
//
 // const ctdlBtcProvider = await CtdlBtcChainlinkProvider.deploy(
 //   feeds.CTDL_WBTC_CURVE_POOL,
 //   feeds.WBTC_BTC_PRICE_FEED
 // );
 // await initFunds[0].citadelPerAssetOracle.addProvider(
 //   address(ctdlWbtcCurveV2Provider)
 // );
 // await initFunds[0].citadelPerAssetOracle.addProvider(
 //   address(ctdlBtcProvider)
 // );
 // console.log(await initFunds[0].citadelPerAssetOracle.callStatic.getData());

  //
  // await initFunds[1].citadelPerAssetOracle.addProvider(
  //   address(ctdlWbtcCurveV2Provider)
  // );
  // await initFunds[1].citadelPerAssetOracle.addProvider(
  //   address(ctdlBtcProvider)
  // );

  const ctdlWibbtcProvider = await CtdlWibbtcLpVaultProvider.deploy(
    feeds.CTDL_WBTC_CURVE_POOL,
    feeds.WBTC_BTC_PRICE_FEED,
    feeds.WIBBTC_LP_VAULT
  );

  //await initFunds[2].citadelPerAssetOracle.addProvider(
  //  address(ctdlWibbtcProvider)
  //);

  const ctdlEthProvider1 = await CtdlEthChainlinkProvider.deploy(
    feeds.CTDL_WBTC_CURVE_POOL,
    feeds.WBTC_BTC_PRICE_FEED,
    feeds.BTC_ETH_PRICE_FEED
  );

  const ctdlEthProvider2 = await CtdlAssetChainlinkProvider.deploy(
    feeds.CTDL_WBTC_CURVE_POOL,
    feeds.WBTC_BTC_PRICE_FEED,
    feeds.BTC_ETH_PRICE_FEED,
    feeds.ETH_USD_PRICE_FEED
  );

  //await initFunds[3].citadelPerAssetOracle.addProvider(
  //  address(ctdlEthProvider1)
  //);
  //await initFunds[3].citadelPerAssetOracle.addProvider(
  //  address(ctdlEthProvider2)
  //);
};

module.exports = oracleSetupMock;
