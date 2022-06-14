const { address } = require("../utils/helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

const initializer = async ({
  gac,
  citadel,
  xCitadel,
  xCitadelVester,
  xCitadelLocker,
  citadelMinter,
  schedule,
  governance,
  xCitadelFees,
  keeper,
  guardian,
  treasuryVault,
  techOps,
  citadelTree,
}) => {
  /// ======= Global Access Control
  if (gac) {
    await gac.connect(governance).initialize(governance.address);
    console.log("GAC initialized.");
  }
  /// ======= Citadel Token
  if (citadel) {
    await citadel
      .connect(governance)
      .initialize("Citadel", "CTDL", gac.address);
    console.log("Citadel initialized.");
  }
  /// ======= Staked (x) Citadel Vault Token
  if (xCitadel) {
    await xCitadel
      .connect(governance)
      .initialize(
        address(citadel),
        address(governance),
        address(keeper),
        address(guardian),
        address(treasuryVault),
        address(techOps),
        address(citadelTree),
        address(xCitadelVester),
        "Staked Citadel",
        "xCTDL",
        xCitadelFees
      );
    console.log("xCitadel initialized.");
  }

  /// ======= Vested Exit | xCitadelVester
  if (xCitadelVester) {
    await xCitadelVester
      .connect(governance)
      .initialize(address(gac), address(citadel), address(xCitadel));
    console.log("xCitadelVester initialized.");
  }
  /// =======  xCitadelLocker
  if (xCitadelLocker) {
    await xCitadelLocker
      .connect(governance)
      .initialize(
        address(xCitadel),
        address(gac),
        "Vote Locked xCitadel",
        "vlCTDL"
      );

    console.log("xCitadelLocker initialized.");

    // add reward token to be distributed to staker
    await xCitadelLocker
      .connect(governance)
      .addReward(address(xCitadel), address(citadelMinter), true);
    console.log("xCitadelLocker reward added.");
  }
  // ========  SupplySchedule || CTDL Token Distribution
  if (schedule) {
    await schedule.connect(governance).initialize(address(gac));
    console.log("schedule initialized.");
  }
  // ========  CitadelMinter || CTDLMinter
  if (citadelMinter) {
    await citadelMinter
      .connect(governance)
      .initialize(
        address(gac),
        address(citadel),
        address(xCitadel),
        address(xCitadelLocker),
        address(schedule)
      );
    console.log("citadelMinter initialized.");
  }
};

module.exports = initializer;
