// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
contract FundingTest is BaseFixture {
    using FixedPointMathLib for uint;

    function setUp() public override {
        BaseFixture.setUp();
    }

    function testDiscountRateBasics() public {
        assertTrue(true);
    /** 
        @fatima: confirm the discount rate is functional
        - access control for setting discount rate (i.e. the proper accounts can call the function and it works. improper accounts revert when attempting to call)
        - access control for setting discount rate limits
        - pausing freezes these functions appropriately
    */
    }

    function testDiscountRateBuys() public {
        assertTrue(true);
        /**
            @fatima: this is a good candidate to generalize using fuzzing: test buys with various discount rates, using fuzzing, and confirm the results.
            sanity check the numerical results (tokens in vs tokens out, based on price and discount rate)
        */ 
    }

    function testBuy() public {
        _testBuy(fundingCvx, 100e18, 100e18);
    }

    function testBuyDifferentDecimals() public {
        // wBTC is an 8 decimal example
        // TODO: Fix comparator calls in inner function as per that functions comment
        // _testBuy(fundingWbtc, 2e8, 2e8);
        assertTrue(true);
    }

    function _testBuy(Funding fundingContract, uint assetIn, uint citadelPrice) internal {
        // just make citadel appear rather than going through minting flow here
        erc20utils.forceMintTo(address(fundingContract), address(citadel), 100000e18);
        
        vm.prank(eoaOracle);

        // CVX funding contract gives us an 18 decimal example
        fundingContract.updateCitadelPriceInAsset(citadelPrice);

        uint expectedAssetOut = assetIn.divWadUp(citadelPrice);
        
        emit log_named_uint("Citadel Price", citadelPrice);

        vm.startPrank(whale);

        require(cvx.balanceOf(whale) >= assetIn, "buyer has insufficent assets for specified buy amount");
        require(citadel.balanceOf(address(fundingContract)) >= expectedAssetOut, "funding has insufficent citadel for specified buy amount");

        comparator.snapPrev();
        cvx.approve(address(fundingContract), cvx.balanceOf(whale));

        fundingContract.deposit(assetIn, 0);
        comparator.snapCurr();

        uint expectedAssetLost = assetIn;
        uint expectedxCitadelGained = citadelPrice;

        // user trades in asset for citadel in xCitadel form.
        assertEq(comparator.diff("citadel.balanceOf(whale)"), 0);
        assertEq(comparator.diff("xCitadel.balanceOf(whale)"), expectedAssetOut);
        assertEq(comparator.negDiff("cvx.balanceOf(whale)"), assetIn);
        
        // funding contract loses citadel and sends asset to saleRecipient. should never hold an xCitadel balance (deposited for each user) (gas costs?)

        // TODO: Improve comparator to easily add new entity for all balance calls.
        assertEq(comparator.negDiff("citadel.balanceOf(fundingCvx)"), expectedAssetOut);
        assertEq(comparator.diff("cvx.balanceOf(treasuryVault)"), assetIn);
        
        assertEq(xCitadel.balanceOf(address(fundingContract)), 0);

        vm.stopPrank();
    }
 }
