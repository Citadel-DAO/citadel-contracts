const deployContracts = async (contractFactories, instances = []) => {
  if (contractFactories.length == 0) {
    return instances;
  }
  const deployedInstance = await contractFactories[0].factory.deploy();
  instances[contractFactories[0].instance] = deployedInstance;
  console.log(
    `${contractFactories[0].instance} address is: , ${deployedInstance.address}`
  );
  return await deployContracts(
    contractFactories.slice(1, contractFactories.length),
    instances
  );
};

module.exports = deployContracts;
