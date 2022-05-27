// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";

contract CtdlWbtcCurveV2Provider is MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public immutable curvePool;

    /// =====================
    /// ===== Functions =====
    /// =====================

    constructor(address _curvePool) {
        curvePool = ICurveCryptoSwap(_curvePool);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestData()
        public
        view
        override
        returns (
            uint256 wbtcPriceInCtdl_,
            uint256 updateTime_,
            bool valid_
        )
    {
        wbtcPriceInCtdl_ = curvePool.price_oracle();
        updateTime_ = block.timestamp;
        valid_ = true;
    }
}
