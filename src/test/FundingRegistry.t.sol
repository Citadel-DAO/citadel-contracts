// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "ds-test/test.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {FundingRegistry} from "../FundingRegistry.sol";
import {Funding} from "../Funding.sol";
import {IERC20} from "../interfaces/erc20/IERC20.sol";
import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";
import "forge-std/console.sol";

contract FundingRegistryTest is BaseFixture {
    using FixedPointMathLib for uint256;

    event Deposit(
        address indexed buyer,
        uint256 assetIn,
        uint256 citadelOutValue
    );

    FundingRegistry public fundingRegistry;
    Funding public fundingTest;

    function setUp() public override {
        BaseFixture.setUp();

        fundingRegistry = new FundingRegistry();

        assertEq(address(0), fundingRegistry.gacAddress());
        assertEq(address(0), fundingRegistry.citadel());
        assertEq(address(0), fundingRegistry.xCitadel());
        assertEq(address(0), fundingRegistry.saleRecipient());
        assertEq(address(0), fundingRegistry.fundingImplementation());

        FundingRegistry.FundingAsset memory fundingAsset = FundingRegistry
            .FundingAsset(address(cvx), address(medianOracleCvx), 100000e18);

        FundingRegistry.FundingAsset[]
            memory initFunds = new FundingRegistry.FundingAsset[](1);

        initFunds[0] = fundingAsset;

        vm.prank(address(governance));

        fundingRegistry.initialize(
            address(gac),
            address(citadel),
            address(xCitadel),
            address(treasuryVault),
            initFunds
        );

        assertEq(fundingRegistry.getAllFundings().length, 1);

        fundingTest = Funding(fundingRegistry.getAllFundings()[0]);

        assertEq(address(fundingTest.citadel()), address(citadel));
    }

    function testDiscountRateBasics() public {
        // calling from correct account

        vm.prank(address(governance));
        fundingTest.setDiscountLimits(10, 50);

        vm.prank(address(policyOps));
        fundingTest.setDiscount(20);
        (
            uint256 discount,
            uint256 minDiscount,
            uint256 maxDiscount,
            ,
            ,

        ) = fundingTest.funding();
        // check if discount is set
        assertEq(discount, 20);

        // setting discount above maximum limit

        vm.prank(address(policyOps));
        vm.expectRevert(bytes("discount > maxDiscount"));
        fundingTest.setDiscount(60);

        // setting discount below minimum limit
        vm.prank(address(policyOps));
        vm.expectRevert(bytes("discount < minDiscount"));
        fundingTest.setDiscount(5);

        // calling setDiscount from a different account
        vm.prank(address(1));
        vm.expectRevert(bytes("GAC: invalid-caller-role-or-address"));
        fundingTest.setDiscount(20);

        // - access control for setting discount rate limits

        // calling with correct role
        vm.prank(address(governance));
        fundingTest.setDiscountLimits(0, 50);
        (, minDiscount, maxDiscount, , , ) = fundingTest.funding();

        // checking if limits are set
        assertEq(minDiscount, 0);
        assertEq(maxDiscount, 50);

        // check discount can not be greater than or equal to MAX_BPS
        vm.prank(address(governance));
        vm.expectRevert(bytes("maxDiscount >= MAX_BPS"));
        fundingTest.setDiscountLimits(0, 10000);

        // calling with wrong address
        vm.prank(address(1));
        vm.expectRevert(bytes("GAC: invalid-caller-role"));
        fundingTest.setDiscountLimits(0, 20);
    }

    /*
    Testing funding data function
    */

    function testFundingData() public {
        FundingRegistry.FundingData[] memory fundingsData = fundingRegistry
            .getAllFundingsData();

        assertEq(address(fundingsData[0].fundingAddress), address(fundingTest));
        assertEq(
            address(fundingsData[0].saleRecipient),
            address(treasuryVault)
        );
    }
}
