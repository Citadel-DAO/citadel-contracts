pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import "../interfaces/erc20/IERC20.sol";

contract VestingTest is BaseFixture {
    using FixedPointMathLib for uint;

    event Claimed(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    event Vest(
        address indexed recipient,
        uint256 _amount,
        uint256 _unlockBegin,
        uint256 _unlockEnd
    );

    function setUp() public override {
        BaseFixture.setUp();
    }

    /*
    Integration flow to test that:
        - A user receives 0 tokens before vesting period begins
        - A user can do a partial claim along the vesting period
        - A user can only claim up to the claimable amount
        - A user can claim with a recepient other than themselves
        - Changing the vesting duration doesn't affect an active vesting period
        - Events logs the expected behaviors properly
    */
    function testClaimFlow() public {
        address user = address(1);
        _stake(user);

        // User attempts to claim before vesting begins (No claimable)
        assertEq(xCitadelVester.claimableBalance(user), 0);

        uint256 userCitadelBefore = citadel.balanceOf(user);
        xCitadelVester.claim(user, 10e18); // No "Claimed" event is emitted as amount is 0
        uint256 userCitadelAfter = citadel.balanceOf(user);

        assertEq(userCitadelAfter - userCitadelBefore, 0); // No tokens were claimed

        // User withdraws from Staked position to begin vesting
        vm.expectEmit(true, false, false, true);
        emit Vest(
            address(user),
            10e18,
            block.timestamp,
            block.timestamp + xCitadelVester.vestingDuration()
        );
        xCitadel.withdrawAll();

        // Claimable balance should still be 0 as no time has elapsed
        assertEq(xCitadelVester.claimableBalance(user), 0);

        // Move forward in time to a fourth of the vesting period
        vm.warp(block.timestamp + xCitadelVester.vestingDuration()/4);

        // Claimable balance should be 1/4 of total amount due to linear vesting
        assertEq(xCitadelVester.claimableBalance(user), 10e18/4);

        // User attempts to claim total amount but only receives the claimable
        userCitadelBefore = citadel.balanceOf(user);

        vm.expectEmit(true, true, false, true);
        emit Claimed(user, user, 10e18/4);
        xCitadelVester.claim(user, 10e18);

        userCitadelAfter = citadel.balanceOf(user);

        assertEq(userCitadelAfter - userCitadelBefore, 10e18/4);

        // Confirm accounting for user
        (,,uint256 lockedAmounts, uint256 claimedAmounts) = xCitadelVester.vesting(user);
        assertEq(lockedAmounts, 10e18);
        assertEq(claimedAmounts, 10e18/4);

        // Move forward in time to a fourth of the vesting period
        vm.warp(block.timestamp + xCitadelVester.vestingDuration()/4);

        // Claimable balance should be 1/4 of total amount due to linear vesting
        assertEq(xCitadelVester.claimableBalance(user), 10e18/4);

        // User claims to a recepient other than themselves
        address user2 = address(2);
        userCitadelBefore = citadel.balanceOf(user2);

        vm.expectEmit(true, true, false, true);
        emit Claimed(user, user2, 10e18/4);
        xCitadelVester.claim(user2, 10e18/4);

        userCitadelAfter = citadel.balanceOf(user2);

        assertEq(userCitadelAfter - userCitadelBefore, 10e18/4);

        // Confirm accounting for user
        (,,lockedAmounts, claimedAmounts) = xCitadelVester.vesting(user);
        assertEq(lockedAmounts, 10e18);
        assertEq(claimedAmounts, 10e18/2);

        // Changing the vesting duration doesn't affect active vesting periods
        vm.stopPrank();
        vm.prank(governance);
        xCitadelVester.setVestingDuration(86400 * 22);
        assertEq(xCitadelVester.vestingDuration(), 86400 * 22);

        // Vesting period remains the same for user
        (uint256 unlockBegin, uint256 unlockEnds,,) = xCitadelVester.vesting(user);
        assertEq(unlockEnds - unlockBegin, xCitadelVester.INITIAL_VESTING_DURATION());

        // Advance to the end of the user's vesting period
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION()/2);

        // User can claim the remaining amount
        vm.startPrank(user);
        userCitadelBefore = citadel.balanceOf(user);

        vm.expectEmit(true, true, false, true);
        emit Claimed(user, user, 10e18/2);
        xCitadelVester.claim(user, 10e18/2);

        userCitadelAfter = citadel.balanceOf(user);

        assertEq(userCitadelAfter - userCitadelBefore, 10e18/2);
    }

    /*
    Integration flow to test that:
        - A user starting a new vesting period while on an active vesting process re-locks
        their assets and adjusts to the new vesting period
    */
    function testDoubleSimultaneousVestingFlow() public {
        address user = address(1);
        _stake(user);

        uint256 firstVestAmount = 10e18/2; // Vesting only half of full amount at first

        // User withdraws half of Staked position to begin vesting
        vm.expectEmit(true, false, false, true);
        emit Vest(
            address(user),
            firstVestAmount,
            block.timestamp,
            block.timestamp + xCitadelVester.vestingDuration()
        );
        xCitadel.withdraw(firstVestAmount);

        // Advance to the middle of the user's vesting period
        vm.warp(block.timestamp + xCitadelVester.vestingDuration()/2);

        // Claimable balance should be firstVestAmount/2
        assertEq(xCitadelVester.claimableBalance(user), firstVestAmount/2);

        // User claims claimable amount
        xCitadelVester.claim(user, firstVestAmount/2);

        (
            uint256 firstUnlockBegin,
            uint256 firstUnlockEnds,
            uint256 lockedAmounts,
            uint256 claimedAmounts
        ) = xCitadelVester.vesting(user);
        assertEq(lockedAmounts, firstVestAmount);
        assertEq(claimedAmounts, firstVestAmount/2);

        // Advance 1/4 of vesting duration to obtain more claimable (Total elapsed: 3/4 of vesting period)
        vm.warp(block.timestamp + xCitadelVester.vestingDuration()/4);

        // Confirm that the amount claimable has been updated
        assertEq(xCitadelVester.claimableBalance(user), firstVestAmount/4);

        // User withdraws the other half of Staked position to begin a new vesting
        uint256 secondVestAmount = 10e18/2; // Vesting the other half of the full amount
        vm.expectEmit(true, false, false, true);
        emit Vest(
            address(user),
            firstVestAmount - claimedAmounts + secondVestAmount,
            block.timestamp,
            block.timestamp + xCitadelVester.vestingDuration()
        );
        xCitadel.withdraw(secondVestAmount);

        // New vesting period starts and all previous claimable is re-locked
        assertEq(xCitadelVester.claimableBalance(user), 0); // Currently reverting (Underflow issue when claimedAmounts exists)

        (
            uint256 secondUnlockBegin,
            uint256 secondUnlockEnds,
            uint256 secondLockedAmounts,
            uint256 secondClaimedAmounts
        ) = xCitadelVester.vesting(user);
        assertEq(secondLockedAmounts, firstVestAmount - claimedAmounts + secondVestAmount); // Total of two vestings minus the already claimed
        assertEq(secondClaimedAmounts, 0); // Claimed amounts are reset after a new vest
        assertEq(secondUnlockBegin, firstUnlockBegin + (xCitadelVester.vestingDuration() * 3)/4); // 3/4 of duration has elapsed since first lock
        assertEq(secondUnlockEnds, firstUnlockEnds + (xCitadelVester.vestingDuration() * 3)/4); // 3/4 of duration has elapsed since first lock

        // Advance to the end of second lock period (1 whole vesting duration length)
        vm.warp(block.timestamp + xCitadelVester.vestingDuration());

        // User should be able to claim the remaining amount from the first vest plus the complete second vest amount
        assertEq(xCitadelVester.claimableBalance(user), firstVestAmount + secondVestAmount - claimedAmounts);

        // User attempts to claim total amount but only receives the claimable (remaining)
        uint256 userCitadelBefore = citadel.balanceOf(user);

        vm.expectEmit(true, true, false, true);
        emit Claimed(user, user, firstVestAmount + secondVestAmount - claimedAmounts);
        xCitadelVester.claim(user, firstVestAmount + secondVestAmount);

        uint256 userCitadelAfter = citadel.balanceOf(user);

        assertEq(userCitadelAfter - userCitadelBefore, firstVestAmount + secondVestAmount - claimedAmounts);
    }


    /*
    Integration flow to test that:
        - A user can do multiple vesting periods properly
    */
    function testDoubleConsecutiveVestingFlow() public {
        address user = address(1);
        _stake(user);

        uint256 firstVestAmount = 10e18; // Vesting full amount staked

        // User withdraws half of Staked position to begin vesting
        vm.expectEmit(true, false, false, true);
        emit Vest(
            address(user),
            firstVestAmount,
            block.timestamp,
            block.timestamp + xCitadelVester.vestingDuration()
        );
        xCitadel.withdraw(firstVestAmount);

        // Advance to end of first vesting period
        vm.warp(block.timestamp + xCitadelVester.vestingDuration());

        // Claimable balance should be firstVestAmount
        assertEq(xCitadelVester.claimableBalance(user), firstVestAmount);

        // User claims full vested amount
        xCitadelVester.claim(user, firstVestAmount);
        (,,uint256 lockedAmounts, uint256 claimedAmounts) = xCitadelVester.vesting(user);
        assertEq(lockedAmounts, firstVestAmount);
        assertEq(claimedAmounts, firstVestAmount);

        // Advance in time to resemble a real case better
        vm.warp(block.timestamp + xCitadelVester.vestingDuration()/2);

        // User stakes again
        vm.stopPrank();
        _stake(user);

        uint256 secondVestAmount = 10e18/2; // Vesting half of newly staked amount

        // User withdraws ramining staked position
        vm.expectEmit(true, false, false, true);
        emit Vest(
            address(user),
            secondVestAmount,
            block.timestamp,
            block.timestamp + xCitadelVester.vestingDuration()
        );
        xCitadel.withdraw(secondVestAmount);

        // Advance to 1/4 of vesting period
        vm.warp(block.timestamp + xCitadelVester.vestingDuration()/4);

        // User should be able to claim secondVestAmount/4
        assertEq(xCitadelVester.claimableBalance(user), secondVestAmount/4);

        // User claims 1/4 of secondVestingAmount
        xCitadelVester.claim(user, secondVestAmount/4);
        (,,lockedAmounts, claimedAmounts) = xCitadelVester.vesting(user);
        assertEq(lockedAmounts, firstVestAmount + secondVestAmount - firstVestAmount); // First vest amount already claimed
        assertEq(claimedAmounts, secondVestAmount/4); // Claimed amounts reset with every new vest
    }



    // Stakes Citadel for a user in preparation for vesting tests
    function _stake(address user) private {
        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 100e18);

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

        // check if user has successfully deposited
        assertEq(userCitadelBefore - userCitadelAfter, 10e18);
        assertEq(xCitadelBalanceAfter - xCitadelBalanceBefore, 10e18);
        assertEq(userXCitadelAfter - userXCitadelBefore, 10e18);
    }
}