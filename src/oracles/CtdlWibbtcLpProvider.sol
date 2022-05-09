// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ChainlinkUtils} from "./ChainlinkUtils.sol";
import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurvePool} from "../interfaces/curve/ICurvePool.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";
import {IVault} from "../interfaces/badger/IVault.sol";

contract CtdlWibbtcLpProvider is ChainlinkUtils, MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public immutable ctdlWbtcCurvePool;

    IVault public immutable wibbtcLpSett;
    ICurvePool public immutable wibbtcCrvPool;

    // Price feeds
    IAggregatorV3Interface public immutable wbtcBtcPriceFeed;

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
        address _wibbtcLpSett
    ) MedianOracleProvider(_medianOracle) {
        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);
        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);

        wibbtcLpSett = IVault(_wibbtcLpSett);
        wibbtcCrvPool = ICurvePool(wibbtcLpSett.token());
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestAnswer()
        public
        view
        override
        returns (uint256 wibbtcLpPriceInCtdl_)
    {
        uint256 wbtcPriceInBtc = safeLatestAnswer(wbtcBtcPriceFeed);
        // TODO: Take this as btc or wbtc?
        uint256 wibbtcLpPriceInBtc = (wibbtcLpSett.getPricePerFullShare() *
            wibbtcCrvPool.get_virtual_price()) / PRECISION;

        // 18 decimals
        uint256 wbtcPriceInCtdl = ctdlWbtcCurvePool.price_oracle();

        wibbtcLpPriceInCtdl_ =
            (wibbtcLpPriceInBtc *
                wbtcPriceInCtdl *
                10**wbtcBtcPriceFeed.decimals()) /
            wbtcPriceInBtc /
            PRECISION;
    }
}
