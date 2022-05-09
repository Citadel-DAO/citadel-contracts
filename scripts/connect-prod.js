const hre = require("hardhat");
const StakedCitadelLockerArtifact = require("../artifacts-external/StakedCitadelLocker.json");
const ethers = hre.ethers;
const getContractFactories = require("./utils/getContractFactories");

const testdeploy = {
  proxyAdmin: "0x8074Db4de0018b2E9E6866ea02c1eb608F751cCB",
  gac: "0xD89AE35cCC177A1C63fdF028f75274C25a00e3c9",
  citadel: "0x26FFe8414440fEEf67712C0825BBffE14215F8A0",
  xCitadel: "0x56f0EAAB23Edb3f74e463C236Fc6b9e859EDd338",
  xCitadelVester: "0x1da6Dae34Fb1e47cfA90FC380e3C562e71aa177B",
  xCitadelLocker: "0xf600CdD2b5AC63Fc4142A6A68FEF62Cc8619B49d",
  supplySchedule: "0xC46e2765658Ae9b5D320ffC6132ec2A2574b9892",
  funding: "0x1857f25A92722F040e3Dd577B078D1acFC2AC924",
  citadelMinter: "0x145e8b97730F9D8F21e962F2fc4Cf4Ee192104FD",
  knightingRound: "0x01c8550aD29C90d1Dd8c207F29Df3AC41FC2a551",
  knightingRoundGuestlist: "0x6debc2E93f6a41be7F4d606f27941FBFfB9E9CE8"
}

const proxies = {
  gac: "0xd93550006E351161A6edFf855fc3E588C46ecfB1",
  citadel: "0xaF0b1FDf9c6BfeC7b3512F207553c0BA00D7f1A2",
  xCitadel: "0xa0FFfb6b575045f215432b3158Ffd0A9ee0454B9",
  xCitadelVester: "0x8e8593369263D99013a6e795634510551F49031d",
  xCitadelLocker: "0x8b9AAb4BE7b25D7794386F8CC217f2d8a9498ee9",
  supplySchedule: "0x90D047E94515af741206033399b3C60114Ed99f2",
  citadelMinter: "0x594691aEa75080dd9B3e91e648Db6045d4fF6E22",
  knightingRound: "0x366f3e96c7a1dC97C261Ffc5119dD9C2A477860E",
  fundingWBTC: "0x2559F79Ffd2b705083A5a23f1fAB4bB03C491435",
  fundingCVX: "0x40927b7bc37380b73DBB60b75d6D5EA308Ec2590",
}

const wbtc_address = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";
const cvx_address = "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b";
const usdc_address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const frax_address = "0x853d955aCEf822Db058eb8505911ED77F175b99e";
const ibbtc_lp_address = "0xaE96fF08771a109dc6650a1BdCa62F2d558E40af";
const bvecvx_address = "0xfd05D3C7fe2924020620A8bE4961bBaA747e6305";

const address = (entity) =>
  entity.address ? entity.address : ethers.constants.AddressZero;

const hashIt = (str) => ethers.utils.keccak256(ethers.utils.toUtf8Bytes(str));

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  // const signers = await ethers.getSigners();
  const [deployer] = await ethers.getSigners();

  /// === Contract Factories
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
    KnightingRoundGuestlist,
    ProxyAdmin
  } = await getContractFactories();

  /// === Deploying Contracts & loggin addresses
  const proxyAdmin = await ProxyAdmin.attach(testdeploy.proxyAdmin);
  console.log("proxy admin address is: ", proxyAdmin.address);

  const gac = GlobalAccessControl.attach(proxies.gac)
  console.log("gac: ", gac.address);

  const citadel = CitadelToken.attach(proxies.citadel)
  console.log("citadel: ", citadel.address);

  const xCitadel = StakedCitadel.attach(proxies.xCitadel)
  console.log("xCitadel: ", xCitadel.address);

  const xCitadelVester = StakedCitadelVester.attach(proxies.xCitadelVester)
  console.log("xCitadelVester: ", xCitadelVester.address);

  const schedule = SupplySchedule.attach(proxies.supplySchedule)
  console.log("schedule: ", schedule.address);

  const citadelMinter = CitadelMinter.attach(proxies.citadelMinter)
  console.log("citadelMinter: ", citadelMinter.address);

  const knightingRound = KnightingRound.attach(proxies.knightingRound)
  console.log("knightingRound: ", knightingRound.address);

  const fundingWBTC = Funding.attach(proxies.fundingWBTC)
  console.log("fundingWBTC: ", fundingWBTC.address);

  const fundingCVX = Funding.attach(proxies.fundingCVX)
  console.log("fundingCVX: ", fundingCVX.address);

  const knightingRoundGuestlist = KnightingRoundGuestlist.attach(testdeploy.knightingRoundGuestlist);
  console.log("knightingRoundGuestlist address is: ", knightingRoundGuestlist.address);

  console.log("/n");

  const wbtc = ERC20Upgradeable.attach(wbtc_address); //
  const cvx = ERC20Upgradeable.attach(cvx_address); //
  const usdc = ERC20Upgradeable.attach(usdc_address); //
  const frax = ERC20Upgradeable.attach(frax_address); //
  const ibbtc_lp = ERC20Upgradeable.attach(ibbtc_lp_address); //
  const bvecvx = ERC20Upgradeable.attach(bvecvx_address); //
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
