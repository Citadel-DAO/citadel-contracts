const { hashIt, address } = require("../utils/helpers");

const grantRoles = async ({
  gac,
  governance,
  citadelMinter,
  treasuryVault,
  techOps,
  treasuryOps,
  policyOps,
}) => {
  await gac
    .connect(governance)
    .grantRole(hashIt("CONTRACT_GOVERNANCE_ROLE"), address(governance));
  await gac
    .connect(governance)
    .grantRole(hashIt("TREASURY_GOVERNANCE_ROLE"), address(treasuryVault));

  await gac
    .connect(governance)
    .grantRole(hashIt("TECH_OPERATIONS_ROLE"), address(techOps));
  await gac
    .connect(governance)
    .grantRole(hashIt("TREASURY_OPERATIONS_ROLE"), address(treasuryOps));
  await gac
    .connect(governance)
    .grantRole(hashIt("POLICY_OPERATIONS_ROLE"), address(policyOps));

  await gac
    .connect(governance)
    .grantRole(hashIt("CITADEL_MINTER_ROLE"), address(citadelMinter));
  await gac
    .connect(governance)
    .grantRole(hashIt("CITADEL_MINTER_ROLE"), address(governance));

  await gac
    .connect(governance)
    .grantRole(hashIt("PAUSER_ROLE"), address(governance));
  await gac
    .connect(governance)
    .grantRole(hashIt("UNPAUSER_ROLE"), address(techOps));
};

module.exports = grantRoles;
