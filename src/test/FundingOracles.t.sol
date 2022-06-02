// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

import {CtdlWbtcCurveV2Provider} from "../oracles/CtdlWbtcCurveV2Provider.sol";
import {CtdlAssetChainlinkProvider} from "../oracles/CtdlAssetChainlinkProvider.sol";

import "../interfaces/citadel/IMedianOracle.sol";

contract FundingOraclesTest is BaseFixture {
    /// =================
    /// ===== State =====
    /// =================

    CtdlWbtcCurveV2Provider ctdlWbtcProvider;
    CtdlAssetChainlinkProvider ctdlCvxProvider;

    /// =====================
    /// ===== Constants =====
    /// =====================

    // TODO: Currenlty set to BADGER/WBTC Curve v2 pool. Replace with CTDL/WBTC pool.
    address constant CTDL_WBTC_CURVE_POOL =
        0x50f3752289e1456BfA505afd37B241bca23e685d;

    address constant WBTC_BTC_PRICE_FEED =
        0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23;

    address constant BTC_ETH_PRICE_FEED =
        0xdeb288F737066589598e9214E782fa5A8eD689e8;
    address constant BTC_USD_PRICE_FEED =
        0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

    address constant FRAX_ETH_PRICE_FEED =
        0x14d04Fff8D21bd62987a5cE9ce543d2F1edF5D3E;
    address constant FRAX_USD_PRICE_FEED =
        0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD;

    address constant USDC_ETH_PRICE_FEED =
        0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
    address constant USDC_USD_PRICE_FEED =
        0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

    address constant CVX_ETH_PRICE_FEED =
        0xC9CbF687f43176B302F03f5e58470b77D07c61c6;
    address constant CVX_USD_PRICE_FEED =
        0xd962fC30A72A84cE50161031391756Bf2876Af5D;

    address constant BADGER_ETH_PRICE_FEED =
        0x58921Ac140522867bf50b9E009599Da0CA4A2379;
    address constant BADGER_USD_PRICE_FEED =
        0x66a47b7206130e6FF64854EF0E1EDfa237E65339;

    /// =================
    /// ===== Tests =====
    /// =================

    function setUp() public override {
        BaseFixture.setUp();

        ctdlWbtcProvider = new CtdlWbtcCurveV2Provider(CTDL_WBTC_CURVE_POOL);

        ctdlCvxProvider = new CtdlAssetChainlinkProvider(
            CTDL_WBTC_CURVE_POOL,
            WBTC_BTC_PRICE_FEED,
            BTC_USD_PRICE_FEED,
            CVX_USD_PRICE_FEED
        );

        medianOracleWbtc.addProvider(address(ctdlWbtcProvider));
        medianOracleCvx.addProvider(address(ctdlCvxProvider));
    }

    function testMedianOracleAccessControl() public {
        vm.startPrank(address(1));
        // Revert message for new versions of Ownable.sol is: "Ownable: caller is not the owner".
        // Version used by MedianOracle might differ or not include a message at all.
        vm.expectRevert("Ownable: caller is not the owner");
        medianOracleCvx.addProvider(address(1));

        vm.expectRevert("Ownable: caller is not the owner");
        medianOracleCvx.removeProvider(address(1));

        vm.expectRevert("Ownable: caller is not the owner");
        medianOracleCvx.setReportExpirationTimeSec(0);

        vm.expectRevert("Ownable: caller is not the owner");
        medianOracleCvx.setReportDelaySec(0);

        vm.expectRevert("Ownable: caller is not the owner");
        medianOracleCvx.setMinimumProviders(0);
        vm.stopPrank();
    }

    function testWbtcProviderCanBePulled() public {
        // Remove keeper provider
        medianOracleWbtc.removeProvider(keeper);

        uint256 ctdlPriceInWbtc = ctdlWbtcProvider.latestAnswer();
        emit log_uint(ctdlPriceInWbtc);

        // Permissionless
        medianOracleWbtc.pullReport(address(ctdlWbtcProvider));

        vm.prank(keeper);
        fundingWbtc.updateCitadelPerAsset();

        assertEq(fundingWbtc.citadelPerAsset(), ctdlPriceInWbtc);
    }

    function testCvxProviderCanBePulled() public {
        // Remove keeper provider
        medianOracleCvx.removeProvider(keeper);

        uint256 ctdlPriceInCvx = ctdlCvxProvider.latestAnswer();
        emit log_uint(ctdlPriceInCvx);

        // Permissionless
        medianOracleCvx.pullReport(address(ctdlCvxProvider));

        vm.prank(keeper);
        fundingCvx.updateCitadelPerAsset();

        assertEq(fundingCvx.citadelPerAsset(), ctdlPriceInCvx);
    }

    function testWbtcOracleCanCombineTwoProviders() public {
        uint256 ctdlPriceInWbtc = ctdlWbtcProvider.latestAnswer();
        emit log_uint(ctdlPriceInWbtc);

        // Permissionless
        medianOracleWbtc.pullReport(address(ctdlWbtcProvider));

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(ctdlPriceInWbtc + 200);
        fundingWbtc.updateCitadelPerAsset();
        vm.stopPrank();

        // Median should be average of both values
        assertEq(fundingWbtc.citadelPerAsset(), ctdlPriceInWbtc + 100);
    }

    function testCvxOracleCanCombineTwoProviders() public {
        uint256 ctdlPriceInCvx = ctdlCvxProvider.latestAnswer();
        emit log_uint(ctdlPriceInCvx);

        // Permissionless
        medianOracleCvx.pullReport(address(ctdlCvxProvider));

        vm.startPrank(keeper);
        medianOracleCvx.pushReport(ctdlPriceInCvx + 200);
        fundingCvx.updateCitadelPerAsset();
        vm.stopPrank();

        // Median should be average of both values
        assertEq(fundingCvx.citadelPerAsset(), ctdlPriceInCvx + 100);
    }

    function testMedianOracleWithExpiration() public {
        medianOracleWbtc.removeProvider(address(ctdlWbtcProvider));
        // Set during initialization in BaseFixture
        assertEq(medianOracleWbtc.reportExpirationTimeSec(), 1 days);

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(1000);
        // TODO: For some reason, the revert string is not being thrown and the trace is wrong.
        //       Maybe a bug in forge?
        skip(1 days + 1);
        vm.expectRevert();
        fundingWbtc.updateCitadelPerAsset();
        vm.stopPrank();
    }

    function testMedianOracleWithMinimumProvidersMoreThan1() public {
        medianOracleWbtc.setMinimumProviders(2);
        assertEq(medianOracleWbtc.minimumProviders(), 2);

        uint256 ctdlPriceInWbtc = ctdlWbtcProvider.latestAnswer();
        emit log_uint(ctdlPriceInWbtc);

        // Permissionless
        medianOracleWbtc.pullReport(address(ctdlWbtcProvider));

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(1000);
        fundingWbtc.updateCitadelPerAsset();
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
        fundingWbtc.updateCitadelPerAsset();
        vm.stopPrank();
    }

    function testValidReportWithZeroPrice() public {
        medianOracleWbtc.removeProvider(address(ctdlWbtcProvider));

        vm.startPrank(keeper);
        medianOracleWbtc.pushReport(0);

        uint256 _citadelPerAsset;
        bool _valid;

        (_citadelPerAsset, _valid) = medianOracleWbtc.getData();

        assertEq(_citadelPerAsset, 0);
        require(_valid, "Price is not valid");

        vm.expectRevert("price must not be zero"); // Only price feed provided 0
        fundingWbtc.updateCitadelPerAsset();
        vm.stopPrank();
    }
}
