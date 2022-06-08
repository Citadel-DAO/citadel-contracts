/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IMedianOracleProvider {
    function decimals() external pure returns (uint256);

    function latestData()
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );

    function latestAnswer() external view returns (uint256);

    function setCurvePool(address _pool) external;
}
