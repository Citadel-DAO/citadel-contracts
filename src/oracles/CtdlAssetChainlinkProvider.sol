// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {MathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {ChainlinkUtils} from "./ChainlinkUtils.sol";
import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

contract CtdlAssetChainlinkProvider is Initializable, ChainlinkUtils, MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public ctdlWbtcCurvePool;

    // Price feeds
    IAggregatorV3Interface public wbtcBtcPriceFeed;
    IAggregatorV3Interface public btcBasePriceFeed;
    IAggregatorV3Interface public assetBasePriceFeed;

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
        address _btcBasePriceFeed,
        address _assetBasePriceFeed
    ) public initializer {
        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);

        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);
        btcBasePriceFeed = IAggregatorV3Interface(_btcBasePriceFeed);
        assetBasePriceFeed = IAggregatorV3Interface(_assetBasePriceFeed);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestData()
        public
        view
        override
        returns (
            uint256 assetPriceInCtdl_,
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
            uint256 btcPriceInBase,
            uint256 updateTime2,
            bool valid2
        ) = safeLatestAnswer(btcBasePriceFeed);
        (
            uint256 assetPriceInBase,
            uint256 updateTime3,
            bool valid3
        ) = safeLatestAnswer(assetBasePriceFeed);

        updateTime_ = MathUpgradeable.min(
            updateTime1,
            MathUpgradeable.min(updateTime2, updateTime3)
        );
        valid_ = valid1 && valid2 && valid3;

        // (10^8) * (10^8) * (10^18) * (10^18) = (10^52) + price value - Shouldn't overflow
        uint256 wbtcPriceInAsset = (wbtcPriceInBtc *
            btcPriceInBase *
            (10**assetBasePriceFeed.decimals()) *
            PRECISION) /
            assetPriceInBase /
            (10**wbtcBtcPriceFeed.decimals()) /
            (10**btcBasePriceFeed.decimals());
        // 18 decimals
        uint256 wbtcPriceInCtdl = ctdlWbtcCurvePool.price_oracle();

        assetPriceInCtdl_ = (wbtcPriceInCtdl * PRECISION) / wbtcPriceInAsset;
    }
}
