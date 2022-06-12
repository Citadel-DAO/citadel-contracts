const { address } = require("../utils/helpers");

const tokenIns = async ({
  wbtc,
  cvx,
  usdc,
  renBTC,
  ibBTC,
  wETH,
  frax,
  badger,
  bveCVX,
}) => {
  return {
    tokenIns: [
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
      {
        name: "bveCVX",
        priceAddress: "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b",
        address: address(bveCVX),
        decimals: 18,
      },
    ],
  };
};

module.exports = tokenIns;
