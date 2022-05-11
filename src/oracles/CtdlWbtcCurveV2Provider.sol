// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";

contract CtdlWbtcCurveV2Provider is MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public immutable curvePool;

    /// =====================
    /// ===== Functions =====
    /// =====================

    constructor(address _medianOracle, address _curvePool)
        MedianOracleProvider(_medianOracle)
    {
        curvePool = ICurveCryptoSwap(_curvePool);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestAnswer()
        public
        view
        override
        returns (uint256 wbtcPriceInCtdl_)
    {
        wbtcPriceInCtdl_ = curvePool.price_oracle();
    }
}
