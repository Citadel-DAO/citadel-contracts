const { address } = require("../utils/helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

const initializer =
  ({
    gac,
    citadel,
    xCitadel,
    xCitadelVester,
    xCitadelLocker,
    citadelMinter,
    schedule,
    fundingWbtc,
    fundingCvx,
  }) =>
  async ({
    governance,
    xCitadelFees,
    keeper,
    guardian,
    treasuryVault,
    techOps,
    citadelTree,
    wbtc,
    cvx,
    eoaOracle,
  }) => {
    /// ======= Global Access Control
    if (gac) {
      await gac.connect(governance).initialize(governance.address);
    }
    /// ======= Citadel Token
    if (citadel) {
      await citadel
        .connect(governance)
        .initialize("Citadel", "CTDL", gac.address);
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
    }

    /// ======= Vested Exit | xCitadelVester
    if (xCitadelVester) {
      await xCitadelVester
        .connect(governance)
        .initialize(address(gac), address(citadel), address(xCitadel));
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
      // add reward token to be distributed to staker
      await xCitadelLocker
        .connect(governance)
        .addReward(address(xCitadel), address(citadelMinter), true);
    }
    // ========  SupplySchedule || CTDL Token Distribution
    if (schedule) {
      await schedule.connect(governance).initialize(address(gac));
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
    }

    /// ========  Funding
    if (fundingWbtc) {
      await fundingWbtc.initialize(
        address(gac),
        address(citadel),
        address(wbtc),
        address(xCitadel),
        address(treasuryVault),
        address(eoaOracle),
        ethers.utils.parseUnits("100", 8)
      );
    }
    if (fundingCvx) {
      await fundingCvx.initialize(
        address(gac),
        address(citadel),
        address(cvx),
        address(xCitadel),
        address(treasuryVault),
        address(eoaOracle),
        ethers.utils.parseUnits("100000", 18)
      );
    }
  };

module.exports = initializer;
