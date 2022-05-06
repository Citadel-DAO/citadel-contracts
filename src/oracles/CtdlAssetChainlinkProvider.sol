// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ChainlinkUtils} from "./ChainlinkUtils.sol";
import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

contract CtdlAssetChainlinkProvider is ChainlinkUtils, MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public immutable ctdlWbtcCurvePool;

    // Price feeds
    IAggregatorV3Interface public immutable wbtcBtcPriceFeed;
    IAggregatorV3Interface public immutable btcBasePriceFeed;
    IAggregatorV3Interface public immutable assetBasePriceFeed;

    /// =====================
    /// ===== Constants =====
    /// =====================

    uint256 constant PRECISION = 10**18;

    /// =====================
    /// ===== Functions =====
    /// =====================

    constructor(
        address _medianOracle,
        address _ctdlWbtcCurvePool,
        address _wbtcBtcPriceFeed,
        address _btcBasePriceFeed,
        address _assetBasePriceFeed
    ) MedianOracleProvider(_medianOracle) {
        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);

        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);
        btcBasePriceFeed = IAggregatorV3Interface(_btcBasePriceFeed);
        assetBasePriceFeed = IAggregatorV3Interface(_assetBasePriceFeed);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestAnswer()
        public
        view
        override
        returns (uint256 assetPriceInCtdl_)
    {
        uint256 wbtcPriceInBtc = safeLatestAnswer(wbtcBtcPriceFeed);
        uint256 btcPriceInBase = safeLatestAnswer(btcBasePriceFeed);
        uint256 assetPriceInBase = safeLatestAnswer(assetBasePriceFeed);

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
