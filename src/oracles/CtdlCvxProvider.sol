// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

contract CtdlCvxProvider {
    /// =================
    /// ===== State =====
    /// =================

    IMedianOracle public immutable medianOracle;
    ICurveCryptoSwap public immutable ctdlWbtcCurvePool;

    // Price feeds
    IAggregatorV3Interface public immutable wbtcBtcPriceFeed;
    IAggregatorV3Interface public immutable btcUsdPriceFeed;
    IAggregatorV3Interface public immutable cvxUsdPriceFeed;

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
        address _btcUsdPriceFeed,
        address _cvxUsdPriceFeed
    ) {
        medianOracle = IMedianOracle(_medianOracle);

        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);

        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);
        btcUsdPriceFeed = IAggregatorV3Interface(_btcUsdPriceFeed);
        cvxUsdPriceFeed = IAggregatorV3Interface(_cvxUsdPriceFeed);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function decimals() external pure returns (uint256) {
        return 18;
    }

    function latestAnswer() public view returns (uint256 cvxPriceInCtdl_) {
        uint256 wbtcPriceInBtc = safeLatestAnswer(wbtcBtcPriceFeed);
        uint256 btcPriceInUsd = safeLatestAnswer(btcUsdPriceFeed);
        uint256 cvxPriceInUsd = safeLatestAnswer(cvxUsdPriceFeed);

        // (10^8) * (10^8) * (10^18) * (10^18) = (10^52) + price value - Shouldn't overflow
        uint256 wbtcPriceInCvx = (uint256(wbtcPriceInBtc) *
            uint256(btcPriceInUsd) *
            (10**cvxUsdPriceFeed.decimals()) *
            PRECISION) /
            uint256(cvxPriceInUsd) /
            (10**wbtcBtcPriceFeed.decimals()) /
            (10**btcUsdPriceFeed.decimals());
        // 18 decimals
        uint256 wbtcPriceInCtdl = ctdlWbtcCurvePool.price_oracle();

        cvxPriceInCtdl_ = (wbtcPriceInCtdl * PRECISION) / wbtcPriceInCvx;
    }

    /// ==========================
    /// ===== Public actions =====
    /// ==========================

    function pushReport() external {
        medianOracle.pushReport(latestAnswer());
    }
    
    /// =========================
    /// ===== Internal view =====
    /// =========================

    function safeLatestAnswer(IAggregatorV3Interface _priceFeed) internal view returns (uint256 answer_) {
        (uint256 roundId, int256 price, , uint256 updateTime, uint256 answeredInRound) = _priceFeed.latestRoundData();

        require(price > 0, "Chainlink price <= 0");
        require(updateTime != 0, "Incomplete round");
        require(answeredInRound >= roundId, "Stale price");

        answer_ = uint256(price);
    }
}
