const pipeActions =
  (initArgs = {}) =>
  async (...actions) => {
    if (actions.length === 0) return initArgs;

    const currentArgs = await actions[0](initArgs);

    return pipeActions({ ...initArgs, ...currentArgs })(
      ...actions.slice(1, actions.length)
    );
  };

module.exports = pipeActions;
