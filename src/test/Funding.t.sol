// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import "../interfaces/erc20/IERC20.sol";

contract FundingTest is BaseFixture {
    using FixedPointMathLib for uint;

    function setUp() public override {
        BaseFixture.setUp();
    }

    function testDiscountRateBasics() public {
    /*
        @fatima: confirm the discount rate is functional
        - access control for setting discount rate (i.e. the proper accounts can call the function and it works. improper accounts revert when attempting to call)
        - access control for setting discount rate limits
        - pausing freezes these functions appropriately
    */

        // calling from correct account
        vm.prank(address(governance));
        fundingCvx.setDiscountLimits(10, 50);
        vm.prank(address(policyOps));
        fundingCvx.setDiscount(20);
        (uint256 discount,uint256 minDiscount,uint256 maxDiscount,,,) = fundingCvx.funding();
        // check if discount is set
        assertEq(discount,20);

        // setting discount above maximum limit

        vm.prank(address(policyOps));
        vm.expectRevert(bytes("discount > maxDiscount"));
        fundingCvx.setDiscount(60);

        // setting discount below minimum limit
        vm.prank(address(policyOps));
        vm.expectRevert(bytes("discount < minDiscount"));
        fundingCvx.setDiscount(5);

        // calling setDiscount from a different account
        vm.prank(address(1));
        vm.expectRevert(bytes("GAC: invalid-caller-role-or-address"));
        fundingCvx.setDiscount(20);

        // - access control for setting discount rate limits

        // calling with correct role
        vm.prank(address(governance));
        fundingCvx.setDiscountLimits(0, 50);
        (,minDiscount,maxDiscount,,,) = fundingCvx.funding();

        // checking if limits are set
        assertEq(minDiscount, 0);
        assertEq(maxDiscount, 50);

        // check discount can not be greater than or equal to MAX_BPS
        vm.prank(address(governance));
        vm.expectRevert(bytes("maxDiscount >= MAX_BPS"));
        fundingCvx.setDiscountLimits(0, 10000);

        // calling with wrong address
        vm.prank(address(1));
        vm.expectRevert(bytes("GAC: invalid-caller-role"));
        fundingCvx.setDiscountLimits(0, 20);

        // - pausing freezes these functions appropriately
        vm.prank(guardian);
        gac.pause();
        vm.prank(address(governance));
        vm.expectRevert(bytes("global-paused"));
        fundingCvx.setDiscountLimits(0, 50);
        vm.prank(address(policyOps));
        vm.expectRevert(bytes("global-paused"));
        fundingCvx.setDiscount(10);
    }

    function testDiscountRateBuysCvx(uint256 assetAmountIn, uint32 discount, uint256 citadelPrice) public {
        _testDiscountRateBuys(fundingCvx, cvx, assetAmountIn, discount, citadelPrice);

    }

    function testDiscountRateBuysWbtc(uint256 assetAmountIn, uint32 discount, uint256 citadelPrice) public {
        // wBTC is an 8 decimal example
        // TODO: Fix comparator calls in inner function as per that functions comment
        _testDiscountRateBuys(fundingWbtc, wbtc, assetAmountIn, discount, citadelPrice);
    }

    function testSetAssetCap() public {
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.setAssetCap(10e18);

        // setting asset cap from correct account
        vm.prank(policyOps);
        fundingCvx.setAssetCap(1000e18);
        (,,,,, uint256 assetCap) = fundingCvx.funding();
        assertEq(assetCap, 1000e18); // check if assetCap is set

        // checking assetCap can not be less than accumulated funds.
         _testDiscountRateBuys(fundingCvx, cvx, 100e18, 3000, 100e18);
        vm.prank(policyOps);
        vm.expectRevert("cannot decrease cap below global sum of assets in");
        fundingCvx.setAssetCap(10e18);

        // Attempt to deposit an amount over the cap reverts
        vm.prank(whale);
        cvx.approve(address(fundingCvx), 1000e18);
        vm.expectRevert("asset funding cap exceeded");
        fundingCvx.deposit(1000e18, 0);

        // Increasing cap allows for deposit
        vm.prank(policyOps);
        fundingCvx.setAssetCap(10000e18);
        (,,,,, assetCap) = fundingCvx.funding();
        assertEq(assetCap, 10000e18); // check if assetCap is set

        uint256 citadelAmountOutExpected = fundingCvx.getAmountOut(1000e18);
        vm.prank(governance);
        citadel.mint(address(fundingCvx), citadelAmountOutExpected + 1000); // fundingContract should have citadel to transfer to user

        vm.startPrank(whale);
        cvx.approve(address(fundingCvx), 1000e18);
        uint256 citadelAmount = fundingCvx.deposit(1000e18, 0);
        assertEq(citadelAmount, citadelAmountOutExpected);
    }

    function testFailClaimAssetToTreasury() public {

        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.claimAssetToTreasury();

        uint256 amount = cvx.balanceOf(address(fundingCvx));
        uint256 balanceBefore = cvx.balanceOf(fundingCvx.saleRecipient());

        vm.prank(treasuryOps);
        fundingCvx.claimAssetToTreasury();

        uint256 balanceAfter = cvx.balanceOf(fundingCvx.saleRecipient());

        // check the difference of saleRecipient's balance is equal to the amount
        assertEq(amount, balanceAfter-balanceBefore);
    }

    function testSweep() public {

        vm.stopPrank();
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.sweep(address(cvx));

        vm.prank(treasuryOps);
        vm.expectRevert("nothing to sweep");
        fundingCvx.sweep(address(cvx));
    }

    function testAccessControl() public {
        // tests to check access controls of various set functions
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.setDiscountManager(address(2));

        // setting discountManager from correct account
        vm.prank(governance);
        fundingCvx.setDiscountManager(address(2));
        (,,,address discountManager,,) = fundingCvx.funding();
        assertEq(discountManager, address(2)); // check if discountManager is set

        vm.prank(address(1));
        vm.expectRevert("onlyCitadelPriceInAssetOracle");
        fundingCvx.updateCitadelPriceInAsset(1000);

        // setting citadelPriceInAsset from correct account
        vm.prank(eoaOracle);
        fundingCvx.updateCitadelPriceInAsset(1000);
        assertEq(fundingCvx.citadelPriceInAsset(), 1000); // check if citadelPriceInAsset is set

        vm.prank(eoaOracle);
        vm.expectRevert("citadel price must not be zero");
        fundingCvx.updateCitadelPriceInAsset(0);

        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.setSaleRecipient(address(2));

        // setting setSaleRecipient from correct account
        vm.prank(governance);
        fundingCvx.setSaleRecipient(address(2));
        assertEq(fundingCvx.saleRecipient(), address(2)); // check if SaleRecipient is set

        vm.prank(governance);
        vm.expectRevert("Funding: sale recipient should not be zero");
        fundingCvx.setSaleRecipient(address(0));
    }

    function testDepositModifiers() public {
        // pausing should freeze deposit
        vm.prank(guardian);
        gac.pause();
        vm.expectRevert(bytes("global-paused"));
        fundingCvx.deposit(10e18, 0);
        vm.prank(address(techOps));
        gac.unpause();

        // flagging citadelPriceFlag should freeze deposit
        vm.prank(governance);
        fundingCvx.setCitadelAssetPriceBounds(0, 5000);
        vm.prank(eoaOracle);
        fundingCvx.updateCitadelPriceInAsset(6000);
        vm.expectRevert(bytes("Funding: citadel price from oracle flagged and pending review"));
        fundingCvx.deposit(10e18, 0);
    }

    function _testDiscountRateBuys(
        Funding fundingContract,
        IERC20 token,
        uint256 _assetAmountIn,
        uint32 _discount,
        uint256 _citadelPrice
    ) public {

        emit log_named_uint("Asset Amount in", _assetAmountIn);
        emit log_named_uint("Discount", _discount);
        emit log_named_uint("Citadel Price", _citadelPrice);

        // discount < MAX_BPS = 10000
        vm.assume(_discount<10000 && _assetAmountIn>0 && _citadelPrice>0 && _assetAmountIn<1000000000e18 && _citadelPrice<1000000000e18);

        // Adjust funding cap as needed
        (,,,,, uint256 assetCap) = fundingContract.funding();
        if (_assetAmountIn > assetCap) {
            vm.prank(policyOps);
            fundingContract.setAssetCap(_assetAmountIn);
        }

        vm.prank(address(governance));
        fundingContract.setDiscountLimits(0, 9999);

        vm.prank(address(policyOps));
        fundingContract.setDiscount(_discount); // set discount

        vm.prank(eoaOracle);
        fundingContract.updateCitadelPriceInAsset(_citadelPrice); // set citadel price

        uint256 citadelAmountOutExpected = fundingContract.getAmountOut(_assetAmountIn);

        vm.prank(governance);
        citadel.mint(address(fundingContract), citadelAmountOutExpected); // fundingContract should have citadel to transfer to user

        vm.startPrank(shrimp);
        erc20utils.forceMintTo(shrimp, address(token), _assetAmountIn);
        token.approve(address(fundingContract), _assetAmountIn);

        comparator.snapPrev();

        // getAmountsOut returns 0 if (amountsIn * price) < 1x10^(decimals)), hence depositFor reverts.
        // This is acceptable since the price has lower bounds. The transaction will revert if the user
        // attempts to deposit the extremely small amounts that would trigger this behavior.
        if(citadelAmountOutExpected == 0) {
            vm.expectRevert("Amount 0");
        }

        uint256 citadelAmountOut = fundingContract.deposit(_assetAmountIn, 0);

        // If revert with "Amount 0", end the test
        if (citadelAmountOut == 0) {
            return;
        }

        vm.stopPrank();

        comparator.snapCurr();

        // Checks (Note: xCTDL 1:1 CTDL at the beginning)
        assertEq(comparator.diff("citadel.balanceOf(shrimp)"), 0);
        assertEq(comparator.diff("xCitadel.balanceOf(shrimp)"), citadelAmountOutExpected);

        if (keccak256(abi.encodePacked(token.symbol())) == keccak256(abi.encodePacked(("CVX")))) {
            assertEq(comparator.negDiff("citadel.balanceOf(fundingCvx)"), citadelAmountOutExpected);
            assertEq(comparator.diff("cvx.balanceOf(treasuryVault)"), _assetAmountIn);
            assertEq(comparator.negDiff("cvx.balanceOf(shrimp)"), _assetAmountIn);
        } else {
            assertEq(comparator.negDiff("citadel.balanceOf(fundingWbtc)"), citadelAmountOutExpected);
            assertEq(comparator.diff("wbtc.balanceOf(treasuryVault)"), _assetAmountIn);
            assertEq(comparator.negDiff("wbtc.balanceOf(shrimp)"), _assetAmountIn);
        }

        // check citadelAmoutOut is same as expected
        assertEq(citadelAmountOut, citadelAmountOutExpected);
        assertEq(xCitadel.balanceOf(address(fundingContract)), 0);

    }

    function _testBuy(Funding fundingContract, uint assetIn, uint citadelPrice) internal {
        // just make citadel appear rather than going through minting flow here
        erc20utils.forceMintTo(address(fundingContract), address(citadel), 100000e18);

        vm.prank(eoaOracle);

        // CVX funding contract gives us a 18 decimal example
        fundingContract.updateCitadelPriceInAsset(citadelPrice);

        uint expectedAssetOut = assetIn.divWadUp(citadelPrice);

        uint256 citadelAmountOutExpected = fundingContract.getAmountOut(assetIn);

        emit log_named_uint("Citadel Price", citadelPrice);

        vm.startPrank(whale);

        require(cvx.balanceOf(whale) >= assetIn, "buyer has insufficent assets for specified buy amount");
        require(citadel.balanceOf(address(fundingContract)) >= expectedAssetOut, "funding has insufficent citadel for specified buy amount");

        comparator.snapPrev();
        cvx.approve(address(fundingContract), cvx.balanceOf(whale));

        uint256 citadelAmountOut = fundingContract.deposit(assetIn, 0);
        comparator.snapCurr();

        // user trades in asset for citadel in xCitadel form.
        assertEq(comparator.diff("citadel.balanceOf(whale)"), 0);
        assertEq(comparator.diff("xCitadel.balanceOf(whale)"), expectedAssetOut);
        assertEq(comparator.negDiff("cvx.balanceOf(whale)"), assetIn);

        // funding contract loses citadel and sends asset to saleRecipient. should never hold a xCitadel balance (deposited for each user) (gas costs?)

        // TODO: Improve comparator to easily add new entity for all balance calls.
        assertEq(comparator.negDiff("citadel.balanceOf(fundingCvx)"), expectedAssetOut);
        assertEq(comparator.diff("cvx.balanceOf(treasuryVault)"), assetIn);

        assertEq(xCitadel.balanceOf(address(fundingContract)), 0);
        assertEq(citadelAmountOut, citadelAmountOutExpected);

        vm.stopPrank();
    }
 }
