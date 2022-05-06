// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IStakedCitadelLocker {
    function initialize(
        address _stakingToken,
        address _gac,
        string calldata name,
        string calldata symbol
    ) external;

    function addReward(
        address _rewardsToken,
        address _distributor,
        bool _useBoost
    ) external;

    function notifyRewardAmount(address _rewardsToken, uint256 _reward)
        external;

    function notifyRewardAmount(
        address _rewardsToken,
        uint256 _reward,
        bytes32 _dataTypeHash
    ) external;

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function withdrawExpiredLocksTo(address _withdrawTo) external;

    function getReward(address _account) external;

    function rewardPerToken(address _rewardsToken) external returns (uint256);

    function lockDuration() external returns (uint256);

    function rewardsDuration() external returns (uint256);

    function processExpiredLocks(bool _relock) external;

    function kickExpiredLocks(address _account) external;

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;

    function shutdown() external;

    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;
}
