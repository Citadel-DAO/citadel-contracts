pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract StakingTest is BaseFixture {
    using FixedPointMathLib for uint;

    function setUp() public override {
        BaseFixture.setUp();
    }

    function testUserStakingFlow() public{
        address user = address(1);

        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 100e18);
        assertEq(citadel.balanceOf(user), 100e18);

        uint256 userCitadelBefore = citadel.balanceOf(user);
        uint256 xCitadelBalanceBefore = xCitadel.balance();
        uint256 userXCitadelBefore = xCitadel.balanceOf(user);
        uint256 xCitadelTotalSupplyBefore = xCitadel.totalSupply();

        vm.startPrank(user);

        // approve staking amount
        citadel.approve(address(xCitadel), 10e18);

        // deposit
        xCitadel.deposit(10e18);

        vm.stopPrank();

        uint256 userCitadelAfter = citadel.balanceOf(user);
        uint256 xCitadelBalanceAfter = xCitadel.balance();
        uint256 userXCitadelAfter = xCitadel.balanceOf(user);
        uint256 xCitadelTotalSupplyAfter = xCitadel.totalSupply();

        // check if user has successfully deposited
        assertEq(userCitadelBefore - userCitadelAfter, 10e18);
        assertEq(userXCitadelAfter - userXCitadelBefore, 10e18); // user should have got same amount as totalSupply was zero
        assertEq(xCitadelBalanceAfter - xCitadelBalanceBefore, 10e18); // xCitadel should have some citadel
        // total supply should have incremented
        assertEq(xCitadelTotalSupplyAfter-xCitadelTotalSupplyBefore, 10e18);

        mintAndDistribute();

        uint256 vestingCitadelBefore = citadel.balanceOf(address(xCitadelVester));

        // user withdraws all amount
        vm.startPrank(user);
        xCitadel.withdrawAll();

        // the amount should go in vesting
        uint256 vestingCitadelAfter = citadel.balanceOf(address(xCitadelVester));

        // as pricePerShare is increased, vesting should receive more amount than deposited.
        uint expectedClaimableBalance = (xCitadel.balance()*userXCitadelAfter)/xCitadel.totalSupply();

        assertEq(vestingCitadelAfter-vestingCitadelBefore, expectedClaimableBalance);

        // moving half duration
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION()/2);

        // at half duration. user should be able claim half amount
        assertEq(xCitadelVester.claimableBalance(user), expectedClaimableBalance/2);

        // move forward so that the vesting period ends
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION());

        // as the vesting period is ended. user should be able claim full amount
        assertEq(xCitadelVester.claimableBalance(user), expectedClaimableBalance);

        userCitadelBefore = citadel.balanceOf(user);

        // expectedClaimableBalance is more than deposited amount
        assertTrue(expectedClaimableBalance > 10e18);
        xCitadelVester.claim(user, expectedClaimableBalance);
        userCitadelAfter = citadel.balanceOf(user);

        // user should have got expected amount back
        assertEq(userCitadelAfter - userCitadelBefore, expectedClaimableBalance);
        vm.stopPrank();

    }

    function mintAndDistribute() public{
        uint pricePerShareBefore = xCitadel.getPricePerFullShare();
        vm.startPrank(policyOps);
        citadelMinter.setCitadelDistributionSplit(0,6000,4000);

        vm.stopPrank();
        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();

        vm.warp(block.timestamp + 1000);

        uint expectedMint = schedule.getMintable(citadelMinter.lastMintTimestamp());

        uint xCitadelTotalSupplyBefore = xCitadel.totalSupply();
        uint citadelBeforeInXcitadel = xCitadel.balance();

        vm.prank(policyOps);
        citadelMinter.mintAndDistribute();

        uint expectedToStakers = expectedMint * 6000 / 10000;
        uint expectedToLockers = expectedMint * 4000 / 10000;
        uint xCitadelTotalSupplyAfter = xCitadel.totalSupply();
        uint citadelAfterInXcitadel = xCitadel.balance();
        uint pricePerShareAfter = xCitadel.getPricePerFullShare();

        // total supply should increase as the amount is deposited
        assertEq(xCitadelTotalSupplyAfter - xCitadelTotalSupplyBefore, expectedToLockers);

        // balance should increase as expectedToLockers is deposited.
        // And expectedToStakers is transferred to xCitadel.
        assertEq(citadelAfterInXcitadel - citadelBeforeInXcitadel, expectedToLockers+expectedToStakers);

        // price per share should increase
        assertEq(pricePerShareAfter - pricePerShareBefore, (expectedToStakers * 1e18)/xCitadelTotalSupplyAfter);
    }

}