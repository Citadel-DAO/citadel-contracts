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

const addOracleProviders = async ({
  CtdlWbtcCurveV2Provider,
  CtdlBtcChainlinkProvider,
  CtdlWibbtcLpVaultProvider,
  CtdlEthChainlinkProvider,
  CtdlAssetChainlinkProvider,
  initFunds,
}) => {
  const ctdlWbtcCurveV2Provider = await CtdlWbtcCurveV2Provider.deploy(
    feeds.CTDL_WBTC_CURVE_POOL
  );

  const ctdlBtcProvider = await CtdlBtcChainlinkProvider.deploy(
    feeds.CTDL_WBTC_CURVE_POOL,
    feeds.WBTC_BTC_PRICE_FEED
  );
  await initFunds[0].citadelPerAssetOracle.addProvider(
    address(ctdlWbtcCurveV2Provider)
  );
  await initFunds[0].citadelPerAssetOracle.addProvider(
    address(ctdlBtcProvider)
  );
  console.log(`wbtc providers added`);

  await initFunds[1].citadelPerAssetOracle.addProvider(
    address(ctdlWbtcCurveV2Provider)
  );
  await initFunds[1].citadelPerAssetOracle.addProvider(
    address(ctdlBtcProvider)
  );
  console.log(`renbtc providers added`);

  const ctdlWibbtcProvider = await CtdlWibbtcLpVaultProvider.deploy(
    feeds.CTDL_WBTC_CURVE_POOL,
    feeds.WBTC_BTC_PRICE_FEED,
    feeds.WIBBTC_LP_VAULT
  );

  await initFunds[2].citadelPerAssetOracle.addProvider(
    address(ctdlWibbtcProvider)
  );

  console.log(`ibBTC providers added`);

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
  await initFunds[3].citadelPerAssetOracle.addProvider(
    address(ctdlEthProvider1)
  );
  await initFunds[3].citadelPerAssetOracle.addProvider(
    address(ctdlEthProvider2)
  );

  const assetETHFeeds = [
    feeds.FRAX_ETH_PRICE_FEED,
    feeds.USDC_ETH_PRICE_FEED,
    feeds.BADGER_ETH_PRICE_FEED,
    feeds.CVX_ETH_PRICE_FEED,
    feeds.CVX_ETH_PRICE_FEED,
  ];

  const assetUsdFeeds = [
    feeds.FRAX_USD_PRICE_FEED,
    feeds.USDC_USD_PRICE_FEED,
    feeds.BADGER_USD_PRICE_FEED,
    feeds.CVX_USD_PRICE_FEED,
    feeds.CVX_USD_PRICE_FEED,
  ];

  const setProvider = async (i = 0) => {
    if (!assetETHFeeds[i]) return;
    const ctdlAssetProvider1 = await CtdlAssetChainlinkProvider.deploy(
      feeds.CTDL_WBTC_CURVE_POOL,
      feeds.WBTC_BTC_PRICE_FEED,
      feeds.BTC_ETH_PRICE_FEED,
      assetUsdFeeds[i]
    );

    const ctdlAssetProvider2 = await CtdlAssetChainlinkProvider.deploy(
      feeds.CTDL_WBTC_CURVE_POOL,
      feeds.WBTC_BTC_PRICE_FEED,
      feeds.BTC_USD_PRICE_FEED,
      assetETHFeeds[i]
    );

    await initFunds[4 + i].citadelPerAssetOracle.addProvider(
      address(ctdlAssetProvider1)
    );
    await initFunds[4 + i].citadelPerAssetOracle.addProvider(
      address(ctdlAssetProvider2)
    );

    return await setProvider(i + 1);
  };

  await setProvider();
};

module.exports = addOracleProviders;
