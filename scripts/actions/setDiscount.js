const setDiscount = async ({
  fundingWbtc,
  fundingCvx,
  governance,
  policyOps,
}) => {
  // set max discount
  await fundingWbtc.connect(governance).setDiscountLimits(0, 1000);
  await fundingCvx.connect(governance).setDiscountLimits(0, 1000);

  // set a discount
  await fundingWbtc.connect(policyOps).setDiscount(1000); // 10 percent discount
  await fundingCvx.connect(policyOps).setDiscount(1000); // 10 percent discount
};

module.exports = setDiscount;
