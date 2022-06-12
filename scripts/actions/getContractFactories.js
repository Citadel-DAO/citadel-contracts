const hre = require("hardhat");

const StakedCitadelLockerArtifact = require("../../artifacts-external/StakedCitadelLocker.json");
const MedianOracleArtifact = require("../../artifacts-external/MedianOracle.json");
const ethers = hre.ethers;

const getContractFactories = async ({ knightingRoundData }) => {
  const signers = await ethers.getSigners();

  const GlobalAccessControl = await ethers.getContractFactory(
    "GlobalAccessControl"
  );

  const CitadelToken = await ethers.getContractFactory("CitadelToken");
  const StakedCitadel = await ethers.getContractFactory("StakedCitadel");
  const StakedCitadelVester = await ethers.getContractFactory(
    "StakedCitadelVester"
  );
  const StakedCitadelLocker = await ethers.getContractFactoryFromArtifact({
    ...StakedCitadelLockerArtifact,
    _format: "hh-sol-artifact-1",
    contractName: "StakedCitadelLocker",
    sourceName: "src/StakedCitadelLocker.sol",
    linkReferences: {
      ...StakedCitadelLockerArtifact.bytecode.linkReferences,
      ...StakedCitadelLockerArtifact.deployedBytecode.linkReferences,
    },
    deployedLinkReferences: {
      ...StakedCitadelLockerArtifact.bytecode.deployedLinkReferences,
      ...StakedCitadelLockerArtifact.deployedBytecode.deployedLinkReferences,
    },
    bytecode: StakedCitadelLockerArtifact.bytecode.object,
    deployedBytecode: StakedCitadelLockerArtifact.deployedBytecode.object,
  });

  const MedianOracle = new ethers.ContractFactory(
    MedianOracleArtifact.abi,
    MedianOracleArtifact.bytecode,
    signers[0]
  );

  const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin");

  const SupplySchedule = await ethers.getContractFactory("SupplySchedule");
  const CitadelMinter = await ethers.getContractFactory("CitadelMinter");

  const KnightingRound = await ethers.getContractFactory("KnightingRound");
  const KnightingRoundWithEth = await ethers.getContractFactory(
    "KnightingRoundWithEth"
  );
  const KnightingRoundRegistry = knightingRoundData
    ? await ethers.getContractFactory("KnightingRoundRegistry", {
        libraries: {
          KnightingRoundData: knightingRoundData.address,
        },
      })
    : null;

  const Funding = await ethers.getContractFactory("Funding");
  const FundingRegistry = await ethers.getContractFactory("FundingRegistry");

  const ERC20Upgradeable = await ethers.getContractFactory("ERC20Upgradeable");

  const KnightingRoundGuestlist = await ethers.getContractFactory(
    "KnightingRoundGuestlist"
  );

  const wBTC = await ethers.getContractFactory("WrapBitcoin");
  const CVX = await ethers.getContractFactory("Convex");
  const USDC = await ethers.getContractFactory("USDC");
  const MintableToken = await ethers.getContractFactory("MintableToken");

  const TransparentUpgradeableProxy = await ethers.getContractFactory(
    "TransparentUpgradeableProxy"
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
    KnightingRoundWithEth,
    KnightingRoundRegistry,
    Funding,
    FundingRegistry,
    ERC20Upgradeable,
    KnightingRoundGuestlist,
    ProxyAdmin,
    wBTC,
    CVX,
    USDC,
    MintableToken,
    TransparentUpgradeableProxy,
    MedianOracle,
  };
};

module.exports = getContractFactories;
