// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract KnightingRoundTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testKnightingRoundIntegration() public {
        bytes32[] memory emptyProof = new bytes32[](1);
        
        // Attempt to deposit before knighting round start
        vm.startPrank(shark);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shark));
        vm.expectRevert("KnightingRound: not started");
        knightingRound.buy(1e8, 0, emptyProof);
        vm.stopPrank();
        
        // Move to knighting round start
        vm.warp(block.timestamp + 100);

        // Users deposit assets
        vm.startPrank(shrimp);
        comparator.snapPrev();

        wbtc.approve(address(knightingRound), wbtc.balanceOf(shrimp));
        knightingRound.buy(1e8, 0, emptyProof);
        comparator.snapCurr();

        assertEq(comparator.negDiff("wbtc.balanceOf(shrimp)"), 1e8);
        assertEq(comparator.diff("knightingRound.boughtAmounts(shrimp)"), 21e18);

        vm.stopPrank();
        
        // Knighting round concludes...
        uint timeTillEnd = knightingRoundParams.start + knightingRoundParams.duration - block.timestamp;
        vm.warp(timeTillEnd);

        // Can't buy after round ends
        // vm.startPrank(shark);
        // vm.expectRevert("KnightingRound: already ended");
        // knightingRound.buy(1e8, 0, emptyProof);
        // vm.stopPrank();

        /*
            Prepare for launch (atomic):
            - Mint initial Citadel based on knighting round assets raised
            - Send 60% to knighting round for distribution
            - finalize() KR to get assets
            - LP with 15% of citadel supply + wBTC amount as per initial price
            - Send 25% remaining to treasury vault
            - Initialize and open funding contracts

            [Citadel now has an open market and funding can commence!]
        */
    }
}
