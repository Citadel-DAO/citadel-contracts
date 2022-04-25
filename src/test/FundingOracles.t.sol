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

    // TODO: Currenlty set to BADGER/WBTC Curve v2 pool. Replace with CTDL/WBTC pool.
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
    }

    // function testMedianOracleAccessControl() public {
    //     vm.startPrank(address(1));
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     medianOracleCvx.addProvider(address(1));

    //     vm.expectRevert("Ownable: caller is not the owner");
    //     medianOracleCvx.removeProvider(address(1));

    //     vm.expectRevert("Ownable: caller is not the owner");
    //     medianOracleCvx.setReportExpirationTimeSec(0);

    //     vm.expectRevert("Ownable: caller is not the owner");
    //     medianOracleCvx.setReportDelaySec(0);

    //     vm.expectRevert("Ownable: caller is not the owner");
    //     medianOracleCvx.setMinimumProviders(0);
    //     vm.stopPrank();
    // }

    function testWbtcProviderCanUpdatePrice() public {
        // Remove keeper provider
        medianOracleWbtc.removeProvider(keeper);

        uint256 ctdlPriceInWbtc = ctdlWbtcProvider.latestAnswer();
        emit log_uint(ctdlPriceInWbtc);

        // Permissionless
        ctdlWbtcProvider.pushReport();

        vm.prank(keeper);
        fundingWbtc.updateCitadelPriceInAsset();

        assertEq(fundingWbtc.citadelPriceInAsset(), ctdlPriceInWbtc);
    }

    function testCvxProviderCanUpdatePrice() public {
        // Remove keeper provider
        medianOracleCvx.removeProvider(keeper);

        uint256 ctdlPriceInCvx = ctdlCvxProvider.latestAnswer();
        emit log_uint(ctdlPriceInCvx);

        // Permissionless
        ctdlCvxProvider.pushReport();

        vm.prank(keeper);
        fundingCvx.updateCitadelPriceInAsset();

        assertEq(fundingCvx.citadelPriceInAsset(), ctdlPriceInCvx);
    }

    function testWbtcOracleCanCombineTwoProviders() public {
        uint256 ctdlPriceInWbtc = ctdlWbtcProvider.latestAnswer();
        emit log_uint(ctdlPriceInWbtc);

        // Permissionless
        ctdlWbtcProvider.pushReport();

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(ctdlPriceInWbtc + 200);
        fundingWbtc.updateCitadelPriceInAsset();
        vm.stopPrank();

        // Median should be average of both values
        assertEq(fundingWbtc.citadelPriceInAsset(), ctdlPriceInWbtc + 100);
    }

    function testCvxOracleCanCombineTwoProviders() public {
        uint256 ctdlPriceInCvx = ctdlCvxProvider.latestAnswer();
        emit log_uint(ctdlPriceInCvx);

        // Permissionless
        ctdlCvxProvider.pushReport();

        vm.startPrank(keeper);
        medianOracleCvx.pushReport(ctdlPriceInCvx + 200);
        fundingCvx.updateCitadelPriceInAsset();
        vm.stopPrank();

        // Median should be average of both values
        assertEq(fundingCvx.citadelPriceInAsset(), ctdlPriceInCvx + 100);
    }

    function testMedianOracleWithExpiration() public {
        medianOracleWbtc.removeProvider(address(ctdlWbtcProvider));

        // Set during initialization in BaseFixture
        assertEq(medianOracleWbtc.reportExpirationTimeSec(), 1 days);

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(1000);
        // TODO: For some reason, the revert string is not being thrown and the trace is wrong. 
        //       Maybe a bug in forge?
        vm.expectRevert();
        skip(1 days + 1);
        fundingWbtc.updateCitadelPriceInAsset();
        vm.stopPrank();
    }

    function testMedianOracleWithMinimumProvidersMoreThan1() public {
        medianOracleWbtc.setMinimumProviders(2);
        assertEq(medianOracleWbtc.minimumProviders(), 2);

        uint256 ctdlPriceInWbtc = ctdlWbtcProvider.latestAnswer();
        emit log_uint(ctdlPriceInWbtc);

        // Permissionless
        ctdlWbtcProvider.pushReport();

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(1000);
        fundingWbtc.updateCitadelPriceInAsset();
        vm.stopPrank();
    }

    function testMedianOracleFailsWhenNotEnoughProviders() public {
        medianOracleWbtc.setMinimumProviders(2);
        assertEq(medianOracleWbtc.minimumProviders(), 2);

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(1000);
        // TODO: For some reason, the revert string is not being thrown and the trace is wrong. 
        //       Maybe a bug in forge?
        vm.expectRevert();
        fundingWbtc.updateCitadelPriceInAsset();
        vm.stopPrank();
    }
}