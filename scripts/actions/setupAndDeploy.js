const getContractFactories = require("./getContractFactories");
const deployContracts = require("./deployContracts");

const setupAndDeploy = async ({ deployer, knightingRoundData }) => {
  const {
    GlobalAccessControl,
    CitadelToken,
    StakedCitadelVester,
    StakedCitadel,
    StakedCitadelLocker,
    SupplySchedule,
    CitadelMinter,
    KnightingRound,
    Funding,
    ERC20Upgradeable,
    MedianOracle,
    KnightingRoundRegistry,
  } = await getContractFactories({ knightingRoundData });

  const {
    gac,
    citadel,
    xCitadel,
    xCitadelVester,
    xCitadelLocker,
    schedule,
    citadelMinter,
    knightingRound,
    fundingWbtc,
    fundingCvx,
    knightingRoundRegistry,
  } = await deployContracts(deployer)([
    { factory: GlobalAccessControl, instance: "gac" },
    { factory: CitadelToken, instance: "citadel" },
    { factory: StakedCitadel, instance: "xCitadel" },
    { factory: StakedCitadelVester, instance: "xCitadelVester" },
    { factory: StakedCitadelLocker, instance: "xCitadelLocker" },
    { factory: SupplySchedule, instance: "schedule" },
    { factory: CitadelMinter, instance: "citadelMinter" },
    { factory: KnightingRound, instance: "knightingRound" },
    { factory: Funding, instance: "fundingWbtc" },
    { factory: Funding, instance: "fundingCvx" },
    { factory: KnightingRoundRegistry, instance: "knightingRoundRegistry" },
  ]);

  const medianOracleWbtc = await MedianOracle.connect(deployer).deploy(
    10000,
    0,
    1
  );
  const medianOracleCvx = await MedianOracle.connect(deployer).deploy(
    10000,
    0,
    1
  );

  return {
    GlobalAccessControl,
    CitadelToken,
    StakedCitadelVester,
    StakedCitadel,
    StakedCitadelLocker,
    SupplySchedule,
    CitadelMinter,
    KnightingRound,
    Funding,
    ERC20Upgradeable,
    gac,
    citadel,
    xCitadel,
    xCitadelVester,
    xCitadelLocker,
    schedule,
    citadelMinter,
    knightingRound,
    fundingWbtc,
    fundingCvx,
    MedianOracle,
    medianOracleWbtc,
    medianOracleCvx,
    knightingRoundRegistry,
  };
};

module.exports = setupAndDeploy;
