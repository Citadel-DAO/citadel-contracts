// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 <= 0.9.0;

interface ISupplySchedule {
    function getMintable() external view returns (uint256);
}
