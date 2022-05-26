const { address } = require("../utils/helpers");

const FundingBonder =
  ({ user, slippage }) =>
  async ({ funding, amount, token }) => {
    await token.connect(user).approve(address(funding), amount);
    await funding.connect(user).deposit(amount, slippage);
  };
module.exports = FundingBonder;
