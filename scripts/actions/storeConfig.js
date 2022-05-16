const storeJson = require("../utils/storeJson");
const { address } = require("../utils/helpers");

const storeConfig = ({
  gac,
  citadel,
  xCitadel,
  xCitadelVester,
  xCitadelLocker,
  schedule,
  citadelMinter,
  knightingRound,
  wbtc,
  cvx,
  basePath,
  configFile,
}) => {
  storeJson(basePath, configFile, {
    gac: address(gac),
    citadel: address(citadel),
    xCitadel: address(xCitadel),
    xCitadelVester: address(xCitadelVester),
    xCitadelLocker: address(xCitadelLocker),
    schedule: address(schedule),
    citadelMinter: address(citadelMinter),
    knightingRound: address(knightingRound),
    wbtc: address(wbtc),
    cvx: address(cvx),
  });
};

module.exports = storeConfig;
