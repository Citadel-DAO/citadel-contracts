// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {ChainlinkUtils} from "./ChainlinkUtils.sol";
import {MedianOracleProvider} from "./MedianOracleProvider.sol";
import {ICurvePool} from "../interfaces/curve/ICurvePool.sol";
import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";
import {IVault} from "../interfaces/badger/IVault.sol";

contract CtdlWibbtcLpVaultProvider is Initializable, ChainlinkUtils, MedianOracleProvider {
    /// =================
    /// ===== State =====
    /// =================

    ICurveCryptoSwap public ctdlWbtcCurvePool;

    IVault public wibbtcLpVault;
    ICurvePool public wibbtcCrvPool;

    // Price feeds
    IAggregatorV3Interface public wbtcBtcPriceFeed;

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
        address _wibbtcLpVault
    ) public initializer {
        ctdlWbtcCurvePool = ICurveCryptoSwap(_ctdlWbtcCurvePool);
        wbtcBtcPriceFeed = IAggregatorV3Interface(_wbtcBtcPriceFeed);

        wibbtcLpVault = IVault(_wibbtcLpVault);
        wibbtcCrvPool = ICurvePool(wibbtcLpVault.token());
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    function latestData()
        public
        view
        override
        returns (
            uint256 wibbtcLpVaultPriceInCtdl_,
            uint256 updateTime_,
            bool valid_
        )
    {
        // 8 decimals
        (
            uint256 wbtcPriceInBtc,
            uint256 updateTime,
            bool valid
        ) = safeLatestAnswer(wbtcBtcPriceFeed);

        updateTime_ = updateTime;
        valid_ = valid;

        // 18 decimals
        uint256 wibbtcLpVaultPriceInBtc = (wibbtcLpVault
            .getPricePerFullShare() * wibbtcCrvPool.get_virtual_price()) /
            PRECISION;

        // 18 decimals
        uint256 wbtcPriceInCtdl = ctdlWbtcCurvePool.price_oracle();

        // 18 decimals
        wibbtcLpVaultPriceInCtdl_ =
            (wibbtcLpVaultPriceInBtc *
                wbtcPriceInCtdl *
                10**wbtcBtcPriceFeed.decimals()) /
            wbtcPriceInBtc /
            PRECISION;
    }
}
