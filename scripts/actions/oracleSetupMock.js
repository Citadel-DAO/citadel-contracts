const hre = require("hardhat");
const ethers = hre.ethers;
const { parseUnits } = ethers.utils;
const { getTokensPrices } = require("../utils/getTokensPrice");
const { address } = require("../utils/helpers");

const oracleSetupMock = async ({ initFunds, keeper, tokenIns, Funding }) => {
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
};

module.exports = oracleSetupMock;
