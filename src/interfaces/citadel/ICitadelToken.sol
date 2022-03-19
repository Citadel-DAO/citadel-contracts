// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 <= 0.9.0;

interface ICitadelToken {
    function mint(address dest, uint256 amount) external;
}
