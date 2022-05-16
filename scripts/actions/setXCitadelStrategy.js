const { address } = require("../utils/helpers");
const setXCitadelStrategy = async ({ xCitadel, governance, citadel }) => {
  const XCitadelStrategy = await ethers.getContractFactory("BrickedStrategy");

  const xCitadelStrategy = await XCitadelStrategy.deploy();

  await xCitadelStrategy
    .connect(governance)
    .initialize(address(xCitadel), address(citadel));
  await xCitadel.connect(governance).setStrategy(address(xCitadelStrategy));

  return { strategyAddress: address(xCitadelStrategy) };
};

module.exports = setXCitadelStrategy;
