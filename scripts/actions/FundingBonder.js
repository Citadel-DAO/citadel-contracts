const { address } = require("../utils/helpers");

const FundingBonder =
  ({ user, slippage }) =>
  async ({ funding, amount, token }) => {
    console.log(`User balance is: ${await token.balanceOf(address(user))} \n
      amount is: ${amount}\n
      citadelPerAsset: ${await funding.connect(user).citadelPerAsset()}
    `);
    await token.connect(user).approve(address(funding), amount);

    await funding.connect(user).deposit(amount, slippage);
  };
module.exports = FundingBonder;
