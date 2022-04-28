const { ethers } = require("ethers");

const calcTokenoutPrice = (desiredPriceInUsd, priceInUsd, decimals) => {
  return ethers.BigNumber.from(desiredPriceInUsd)
    .mul(ethers.BigNumber.from(10).pow(ethers.BigNumber.from(decimals)))
    .div(ethers.BigNumber.from(priceInUsd));
};


