// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {ChainlinkUtils} from "./ChainlinkUtils.sol";
import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

contract CtdlBtcChainlinkProvider is Initializable, ChainlinkUtils, MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public ctdlWbtcCurvePool;

    // Price feeds
    IAggregatorV3Interface public wbtcBtcPriceFeed;

    /// =====================
    /// ===== Functions =====s
    /// =====================

    function initialize(address _ctdlWbtcCurvePool, address _wbtcBtcPriceFeed) public initializer {
        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);

        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestData()
        public
        view
        override
        returns (
            uint256 btcPriceInCtdl_,
            uint256 updateTime_,
            bool valid_
        )
    {
        (
            uint256 wbtcPriceInBtc,
            uint256 updateTime,
            bool valid
        ) = safeLatestAnswer(wbtcBtcPriceFeed);

        updateTime_ = updateTime;
        valid_ = valid;

        // 18 decimals
        uint256 wbtcPriceInCtdl = ctdlWbtcCurvePool.price_oracle();

        btcPriceInCtdl_ =
            (wbtcPriceInCtdl * 10**wbtcBtcPriceFeed.decimals()) /
            wbtcPriceInBtc;
    }
}
