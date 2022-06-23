// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

/// @notice Tests for SupplySchedule Contract
contract SupplyScheduleTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    /*
     Unit tests for setMintingStart function
    */
    function testSetMintingStart() public {
        // should revert as not called from correct caller
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        schedule.setMintingStart(1000);

        // Now governance will call
        vm.startPrank(governance);

        // should revert as the input time is in past
        vm.expectRevert(
            "SupplySchedule: minting must start at or after current time"
        );
        schedule.setMintingStart(block.timestamp - 10);

        uint256 timestamp = block.timestamp + 1000;
        schedule.setMintingStart(timestamp);
        assertEq(schedule.globalStartTimestamp(), timestamp); // check if globalStartTimeStamp is set.

        // should revert as minting already started
        vm.expectRevert("SupplySchedule: minting already started");
        schedule.setMintingStart(block.timestamp + 1000);
        vm.stopPrank();
    }

    /*
    Unit tests for setEpochRate function
    */

    function testSetEpochRate() public {
        uint256 epochLength = schedule.epochLength();
        uint256 epochRate = 514986000000000000000000 / epochLength;
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        schedule.setEpochRate(0, epochRate);

        vm.startPrank(governance);

        // initial epochRates are aleady set in initialize function so the transaction should revert.
        vm.expectRevert("SupplySchedule: rate already set for given epoch");
        schedule.setEpochRate(0, epochRate);

        schedule.setEpochRate(7, epochRate);
        assertEq(schedule.epochRate(7), epochRate); // check if epochRate is set

        vm.stopPrank();
    }

    /*
    Unit tests for getMintable Function
    Checks if getMintable returns the correct mintable amount for every epochs
    */
    function testGetMintable() public {
        uint256 epochLength = schedule.epochLength();

        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();

        vm.warp(block.timestamp + 1 * epochLength); // 1 epoch passed

        uint256 expectedMintable = schedule.epochRate(0) * epochLength;

        uint256 mintable = schedule.getMintable(
            citadelMinter.lastMintTimestamp()
        );

        assertEq(expectedMintable, mintable); // check

        vm.warp(block.timestamp + 2 * epochLength); // 2 more epoch passed

        expectedMintable +=
            schedule.epochRate(1) *
            epochLength +
            schedule.epochRate(2) *
            epochLength;
        mintable = schedule.getMintable(citadelMinter.lastMintTimestamp());

        assertEq(expectedMintable, mintable);

        vm.warp(block.timestamp + epochLength + 1000); // 1 more epoch and some time passed
        expectedMintable +=
            schedule.epochRate(3) *
            epochLength +
            schedule.epochRate(4) *
            1000;

        mintable = schedule.getMintable(citadelMinter.lastMintTimestamp());

        assertEq(expectedMintable, mintable);
    }
}
