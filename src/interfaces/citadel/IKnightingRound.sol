/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IKnightingRound {
    function boughtAmounts(address account) external view returns (uint256);
    function tokenOutPerTokenIn() external view returns (uint256);
}
