// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 <= 0.9.0;

interface IxCitadelLocker {
    function notifyRewardAmount(address _rewardsToken, uint256 _reward)
        external;
}
