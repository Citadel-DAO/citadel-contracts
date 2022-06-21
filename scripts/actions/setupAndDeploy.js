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
    FundingRegistry,
    CtdlWbtcCurveV2Provider,
    CtdlBtcChainlinkProvider,
    CtdlWibbtcLpVaultProvider,
    CtdlEthChainlinkProvider,
    CtdlAssetChainlinkProvider,
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
    knightingRoundRegistry,
    fundingRegistry,
    fundingImplementation,
  } = await deployContracts(deployer)([
    { factory: GlobalAccessControl, instance: "gac" },
    { factory: CitadelToken, instance: "citadel" },
    { factory: StakedCitadel, instance: "xCitadel" },
    { factory: StakedCitadelVester, instance: "xCitadelVester" },
    { factory: StakedCitadelLocker, instance: "xCitadelLocker" },
    { factory: SupplySchedule, instance: "schedule" },
    { factory: CitadelMinter, instance: "citadelMinter" },
    { factory: KnightingRound, instance: "knightingRound" },
    { factory: Funding, instance: "fundingImplementation" },
    { factory: KnightingRoundRegistry, instance: "knightingRoundRegistry" },
    { factory: FundingRegistry, instance: "fundingRegistry" },
  ]);

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
    MedianOracle,
    knightingRoundRegistry,
    fundingRegistry,
    fundingImplementation,
    CtdlWbtcCurveV2Provider,
    CtdlBtcChainlinkProvider,
    CtdlWibbtcLpVaultProvider,
    CtdlEthChainlinkProvider,
    CtdlAssetChainlinkProvider,
  };
};

module.exports = setupAndDeploy;
