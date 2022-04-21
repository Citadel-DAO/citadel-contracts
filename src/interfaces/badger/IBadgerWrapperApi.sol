// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 <= 0.9.0;
pragma experimental ABIEncoderV2;

import "../erc20/IERC20.sol";

interface BadgerWrapperAPI is IERC20 {
    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalWrapperBalance(address account) external view returns (uint256);

    function totalVaultBalance(address account) external view returns (uint256);
}