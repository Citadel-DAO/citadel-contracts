// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 <= 0.9.0;

interface ICurveCryptoSwap {
    function price_oracle() external view returns (uint256);
}
