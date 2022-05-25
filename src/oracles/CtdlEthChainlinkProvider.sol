// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ChainlinkUtils} from "./ChainlinkUtils.sol";
import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

contract CtdlEthChainlinkProvider is ChainlinkUtils, MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public immutable ctdlWbtcCurvePool;

    // Price feeds
    IAggregatorV3Interface public immutable wbtcBtcPriceFeed;
    IAggregatorV3Interface public immutable btcEthPriceFeed;

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
        address _btcEthPriceFeed
    ) MedianOracleProvider(_medianOracle) {
        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);

        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);
        btcEthPriceFeed = IAggregatorV3Interface(_btcEthPriceFeed);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestAnswer()
        public
        view
        override
        returns (uint256 ethPriceInCtdl_)
    {
        uint256 wbtcPriceInBtc = safeLatestAnswer(wbtcBtcPriceFeed);
        uint256 btcPriceInEth = safeLatestAnswer(btcEthPriceFeed);

        // (10^8) * (10^8) * (10^18) = (10^34) + price value - Shouldn't overflow
        uint256 wbtcPriceInEth = (wbtcPriceInBtc * btcPriceInEth * PRECISION) /
            (10**wbtcBtcPriceFeed.decimals()) /
            (10**btcEthPriceFeed.decimals());
        // 18 decimals
        uint256 wbtcPriceInCtdl = ctdlWbtcCurvePool.price_oracle();

        ethPriceInCtdl_ = (wbtcPriceInCtdl * PRECISION) / wbtcPriceInEth;
    }
}
