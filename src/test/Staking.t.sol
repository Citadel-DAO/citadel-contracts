pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import "../interfaces/erc20/IERC20.sol";

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
        uint256 xCitadelBalanceBefore = citadel.balanceOf(address(xCitadel));
        uint256 userXCitadelBefore = xCitadel.balanceOf(user);

        vm.startPrank(user);

        // approve staking amount
        citadel.approve(address(xCitadel), 10e18);

        // deposit
        xCitadel.deposit(10e18);

        uint256 userCitadelAfter = citadel.balanceOf(user);
        uint256 xCitadelBalanceAfter = citadel.balanceOf(address(xCitadel));
        uint256 userXCitadelAfter = xCitadel.balanceOf(user);

        emit log_named_uint("xCitadel received",userXCitadelAfter-userXCitadelBefore);

        // check if user has successfully deposited
        assertEq(userCitadelBefore - userCitadelAfter, 10e18);
        assertEq(xCitadelBalanceAfter - xCitadelBalanceBefore, 10e18);

        uint256 vestingCitadelBefore = citadel.balanceOf(address(xCitadelVester));

        // user withdraws all amount
        xCitadel.withdrawAll();

        // the amount should go in vesting
        uint256 vestingCitadelAfter = citadel.balanceOf(address(xCitadelVester));

        emit log_named_uint("Vesting Citadel received",vestingCitadelAfter-vestingCitadelBefore);

        // should have sent full amount to vesting
        assertEq(vestingCitadelAfter-vestingCitadelBefore, 10e18);

        // moving half duration
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION()/2);

        uint256 claimableAmount = xCitadelVester.claimableBalance(user);

        // at half duration. user should be able claim half amount
        assertEq(claimableAmount, 10e18/2);

        // move forward so that the vesting period ends
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION());

        claimableAmount = xCitadelVester.claimableBalance(user);

        // as the vesting period is ended. user should be able claim full amount
        assertEq(claimableAmount, 10e18);

        userCitadelBefore = citadel.balanceOf(user);
        xCitadelVester.claim(user, 10e18);
        userCitadelAfter = citadel.balanceOf(user);

        // user should have got full amount back
        assertEq(userCitadelAfter - userCitadelBefore, 10e18);
        vm.stopPrank();
    }
}