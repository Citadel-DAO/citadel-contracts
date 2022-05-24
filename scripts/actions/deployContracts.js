const deployContracts = (deployer) => async (contractFactories, instances = []) => {
  if (contractFactories.length == 0) {
    return instances;
  }
  const factory = contractFactories[0].factory.connect(deployer)
  const deployedInstance = await factory.deploy();
  instances[contractFactories[0].instance] = deployedInstance;
  console.log(
    `${contractFactories[0].instance} address is: ${deployedInstance.address}`
  );
  return await deployContracts(deployer)(
    contractFactories.slice(1, contractFactories.length),
    instances
  );
};

module.exports = deployContracts;
