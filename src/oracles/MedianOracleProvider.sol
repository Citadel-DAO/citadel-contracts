// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract MedianOracleProvider {
    /// =======================
    /// ===== Public view =====
    /// =======================

    function decimals() external pure virtual returns (uint256) {
        return 18;
    }

    function latestData()
        public
        view
        virtual
        returns (
            uint256,
            uint256,
            bool
        );

    function latestAnswer() public view virtual returns (uint256 price_) {
        (uint256 answer, , bool valid) = latestData();

        require(valid);

        price_ = answer;
    }
}
