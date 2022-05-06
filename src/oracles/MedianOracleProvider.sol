// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";

abstract contract MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    IMedianOracle public immutable medianOracle;

    /// =====================
    /// ===== Functions =====
    /// =====================

    constructor(address _medianOracle) {
        medianOracle = IMedianOracle(_medianOracle);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function decimals() external pure virtual returns (uint256) {
        return 18;
    }

    function latestAnswer() public view virtual returns (uint256);

    /// ==========================
    /// ===== Public actions =====
    /// ==========================

    function pushReport() external {
        medianOracle.pushReport(latestAnswer());
    }
}
