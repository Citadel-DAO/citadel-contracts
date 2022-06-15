// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function token() external view returns (address);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);
}
