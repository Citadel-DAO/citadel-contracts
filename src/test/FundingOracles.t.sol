// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

import {CtdlWbtcCurveV2Provider} from "../oracles/CtdlWbtcCurveV2Provider.sol";
import {CtdlCvxProvider} from "../oracles/CtdlCvxProvider.sol";

contract FundingOraclesTest is BaseFixture {
    /// =================
    /// ===== State =====
    /// =================

    CtdlWbtcCurveV2Provider ctdlWbtcProvider;
    CtdlCvxProvider ctdlCvxProvider;

    /// =====================
    /// ===== Constants =====
    /// =====================

    // TODO: Replace with actual pool
    address constant CTDL_WBTC_CURVE_POOL = 0x50f3752289e1456BfA505afd37B241bca23e685d;

    address constant WBTC_BTC_PRICE_FEED = 0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23;
    address constant BTC_USD_PRICE_FEED = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    address constant CVX_USD_PRICE_FEED = 0xd962fC30A72A84cE50161031391756Bf2876Af5D;

    /// =================
    /// ===== Tests =====
    /// =================

    function setUp() public override {
        BaseFixture.setUp();

        ctdlWbtcProvider = new CtdlWbtcCurveV2Provider(
            address(medianOracleWbtc),
            CTDL_WBTC_CURVE_POOL
        );

        ctdlCvxProvider = new CtdlCvxProvider(
            address(medianOracleCvx),
            CTDL_WBTC_CURVE_POOL,
            WBTC_BTC_PRICE_FEED,
            BTC_USD_PRICE_FEED,
            CVX_USD_PRICE_FEED
        );

        medianOracleWbtc.addProvider(address(ctdlWbtcProvider));
        medianOracleCvx.addProvider(address(ctdlCvxProvider));

        // Remove keeper for general tests
        medianOracleWbtc.removeProvider(keeper);
        medianOracleCvx.removeProvider(keeper);
    }

    function testCvxOracleCanUpdatePrice() public {
        uint256 ctdlPriceInCvx = ctdlCvxProvider.latestAnswer();
        emit log_uint(ctdlPriceInCvx);

        // Permissionless
        ctdlCvxProvider.pushReport();

        vm.prank(keeper);
        fundingCvx.updateCitadelPriceInAsset();

        assertEq(fundingCvx.citadelPriceInAsset(), ctdlPriceInCvx);
    }

    function testWbtcOracleCanUpdatePrice() public {
        uint256 ctdlPriceInWbtc = ctdlWbtcProvider.latestAnswer();
        emit log_uint(ctdlPriceInWbtc);

        // Permissionless
        ctdlWbtcProvider.pushReport();

        vm.prank(keeper);
        fundingWbtc.updateCitadelPriceInAsset();

        assertEq(fundingWbtc.citadelPriceInAsset(), ctdlPriceInWbtc);
    }

    function testFundingOraclesFlow() public {
        /*
            - update CTDL/USD
            - update ASSET/USD
            - update xCTDL/CTDL
            - permissions
            - swap oracle addresses
        */
    }
}