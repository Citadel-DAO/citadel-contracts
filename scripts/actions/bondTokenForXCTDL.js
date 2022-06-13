const hre = require("hardhat");
const ethers = hre.ethers;
const { address } = require("../utils/helpers");

const { formatUnits, parseUnits } = ethers.utils;

const FundingBonder = require("./FundingBonder");

const { getTokensPrices } = require("../utils/getTokensPrice");

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

    await currentFunding.connect(keeper).updateCitadelPerAsset();

    await fundingBonder({
      funding: currentFunding,
      amount: apeGeneral,
      token: asset,
    });

    return await allFundingsBonder(i + 1);
  };

  await allFundingsBonder();

  //console.log(`Funding contract address: `, fundingWbtc.address);
  //console.log(`Asset contract address: `, wbtc.address);
  //await fundingBonder({
  //  funding: fundingWbtc,
  //  amount: apeWbtcAmount,
  //  token: wbtc,
  //});
  //
  //await fundingBonder({
  //  funding: fundingCvx,
  //  amount: apeCvxAmount,
  //  token: cvx,
  //});

  // user should be getting ~200 xCTDL
  console.log(
    `balance of xCTDL after two deposits: ${formatUnits(
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
