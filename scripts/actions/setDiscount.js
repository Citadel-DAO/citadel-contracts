const setDiscount = async ({
  fundingWbtc,
  fundingCvx,
  governance,
  policyOps,
  fundingRegistry,
  Funding,
}) => {
  // set max discount
  await fundingWbtc.connect(governance).setDiscountLimits(0, 1000);
  await fundingCvx.connect(governance).setDiscountLimits(0, 1000);

  // set a discount
  await fundingWbtc.connect(policyOps).setDiscount(1000); // 10 percent discount
  await fundingCvx.connect(policyOps).setDiscount(1000); // 10 percent discount

  const fundingsList = await fundingRegistry.getAllFundings();

  const discountAllFundings = async (i = 0) => {
    const currentFunding = fundingsList[i]
      ? Funding.attach(fundingsList[i])
      : undefined;
    if (!currentFunding) return;

    console.log("setting discount for funding: ", currentFunding.address);

    await currentFunding.connect(governance).setDiscountLimits(0, 1000);
    await currentFunding.connect(policyOps).setDiscount(1000);

    return await discountAllFundings(i + 1);
  };

  await discountAllFundings();
};

module.exports = setDiscount;
