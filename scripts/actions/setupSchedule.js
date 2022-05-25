const setupSchedule = async ({schedule, governance}) => {

    let epochLength = await schedule.epochLength()
    await schedule.connect(governance).setEpochRate(
      0,
      ethers.BigNumber.from("593962000000000000000000").div(epochLength) 
  );
  epochLength = await schedule.epochLength()
    await schedule.connect(governance).setEpochRate(
      1,
      ethers.BigNumber.from("591445000000000000000000").div(epochLength) 
  );
  epochLength = await schedule.epochLength()
    await schedule.connect(governance).setEpochRate(
      2,
      ethers.BigNumber.from("585021000000000000000000").div(epochLength) 
  );
  epochLength = await schedule.epochLength()
    await schedule.connect(governance).setEpochRate(
      3,
      ethers.BigNumber.from("574138000000000000000000").div(epochLength) 
  );
  epochLength = await schedule.epochLength()
    await schedule.connect(governance).setEpochRate(
      4,
      ethers.BigNumber.from("558275000000000000000000").div(epochLength) 
  );
  
  epochLength = await schedule.epochLength()
    await schedule.connect(governance).setEpochRate(
      5,
      ethers.BigNumber.from("536986000000000000000000").div(epochLength) 
  );

}

module.exports = setupSchedule