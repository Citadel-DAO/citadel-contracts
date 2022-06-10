const { ethers } = require("ethers");
const axios = require("axios");

const calcTokenOutPerTokenIn = (desiredPriceInUsd, priceInUsd, decimals) => {
  console.log("Price in USD: ", priceInUsd);
  return ethers.BigNumber.from(parseInt(desiredPriceInUsd * 10 ** 4))
    .mul(ethers.BigNumber.from(10).pow(18))
    .div(ethers.BigNumber.from(parseInt(priceInUsd * 10 ** 4)));
};

const getTokensPrices = (tokensList) => {
  const reqUrl = `
https://api.coingecko.com/api/v3/simple/token_price/ethereum?contract_addresses=${tokensList.join(
    ","
  )}&vs_currencies=usd
`;

  return new Promise((resolve, reject) => {
    axios
      .get(reqUrl)
      .then(function (response) {
        return resolve(response.data);
      })
      .catch(function (error) {
        return reject(error);
      });
  });
};

module.exports = { calcTokenOutPerTokenIn, getTokensPrices };
