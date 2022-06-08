// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {MathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {ChainlinkUtils} from "./ChainlinkUtils.sol";
import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

contract CtdlEthChainlinkProvider is Initializable, ChainlinkUtils, MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public ctdlWbtcCurvePool;

    // Price feeds
    IAggregatorV3Interface public wbtcBtcPriceFeed;
    IAggregatorV3Interface public btcEthPriceFeed;

    /// =====================
    /// ===== Constants =====
    /// =====================

    uint256 constant PRECISION = 10**18;

    /// =====================
    /// ===== Functions =====
    /// =====================

    function initialize(
        address _ctdlWbtcCurvePool,
        address _wbtcBtcPriceFeed,
        address _btcEthPriceFeed
    ) public initializer {
        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);

        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);
        btcEthPriceFeed = IAggregatorV3Interface(_btcEthPriceFeed);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestData()
        public
        view
        override
        returns (
            uint256 ethPriceInCtdl_,
            uint256 updateTime_,
            bool valid_
        )
    {
        (
            uint256 wbtcPriceInBtc,
            uint256 updateTime1,
            bool valid1
        ) = safeLatestAnswer(wbtcBtcPriceFeed);
        (
            uint256 btcPriceInEth,
            uint256 updateTime2,
            bool valid2
        ) = safeLatestAnswer(btcEthPriceFeed);

        updateTime_ = MathUpgradeable.min(updateTime1, updateTime2);
        valid_ = valid1 && valid2;

        // (10^8) * (10^8) * (10^18) = (10^34) + price value - Shouldn't overflow
        uint256 wbtcPriceInEth = (wbtcPriceInBtc * btcPriceInEth * PRECISION) /
            (10**wbtcBtcPriceFeed.decimals()) /
            (10**btcEthPriceFeed.decimals());
        // 18 decimals
        uint256 wbtcPriceInCtdl = ctdlWbtcCurvePool.price_oracle();

        ethPriceInCtdl_ = (wbtcPriceInCtdl * PRECISION) / wbtcPriceInEth;
    }
}
