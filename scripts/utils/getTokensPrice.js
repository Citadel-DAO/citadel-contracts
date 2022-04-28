const { ethers } = require("ethers");
const axios = require("axios");

const calcTokenoutPrice = (desiredPriceInUsd, priceInUsd, decimals) => {
  return ethers.BigNumber.from(desiredPriceInUsd)
    .mul(ethers.BigNumber.from(10).pow(ethers.BigNumber.from(decimals)))
    .div(ethers.BigNumber.from(priceInUsd));
};

const getTokensPrices = (tokensList) => {
  const reqUrl = `
https://api.coingecko.com/api/v3/simple/token_price/ethereum?contract_addresses=${tokensList.join(
    ","
  )}&vs_currencies=usd
`;

  console.log(reqUrl);

  return new Promise((resolve, reject) => {
    axios
      .get(reqUrl)
      .then(function (response) {
        // handle success
        console.log(response.data);
      })
      .catch(function (error) {
        // handle error
        console.log(error);
      });
  });
};

module.exports = { calcTokenoutPrice, getTokensPrices };
