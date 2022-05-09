const hre = require("hardhat");
const ethers = hre.ethers;

const getRoleSigners = async () => {
  const signers = await ethers.getSigners();

  const governance = signers[12];
  const keeper = signers[11];
  const guardian = signers[13];
  const treasuryVault = signers[14];
  const techOps = signers[15];
  const treasuryOps = signers[18];
  const citadelTree = signers[16];
  const policyOps = signers[19];

  const rando = signers[17];

  const whale = signers[7];
  const shrimp = signers[8];
  const shark = signers[9];

  const eoaOracle = signers[3];

  return {
    governance,
    keeper,
    guardian,
    treasuryVault,
    techOps,
    treasuryOps,
    citadelTree,
    policyOps,
    rando,
    whale,
    shrimp,
    shark,
    eoaOracle,
  };
};

module.exports = getRoleSigners;
