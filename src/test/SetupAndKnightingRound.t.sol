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

        vm.expectRevert("_tokenInAmount should be > 0");
        knightingRound.buy(0, 0, emptyProof);

        comparator.snapPrev();

        uint256 tokenOutAmountExpected = knightingRound.getAmountOut(1e8);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shrimp));
        uint256 tokenOutAmount = knightingRound.buy(1e8, 0, emptyProof);
        comparator.snapCurr();

        assertEq(knightingRound.totalTokenIn(),1e8); // totalTokenIn should be equal to deposit
        assertEq(tokenOutAmount, tokenOutAmountExpected); // transferred amount should be equal to expected
        assertEq(knightingRound.totalTokenOutBought(), tokenOutAmount); 
        assertEq(knightingRound.daoVotedFor(shrimp), 0); // daoVotedFor should be set

        assertEq(comparator.negDiff("wbtc.balanceOf(shrimp)"), 1e8);
        assertEq(comparator.diff("knightingRound.boughtAmounts(shrimp)"), 21e18);

        // tokenInLimit = 100e8 so transaction should revert
        vm.expectRevert("total amount exceeded");
        knightingRound.buy(100e8, 0, emptyProof);
        assertEq(knightingRound.totalTokenIn(),1e8); // totelTokenIn should be same 

        // buying again

        uint256 tokenOutAmount2 =knightingRound.buy(1e8, 0, emptyProof);
        assertEq(knightingRound.totalTokenIn(),2e8); // should increment 
        assertEq(knightingRound.totalTokenOutBought(), tokenOutAmount + tokenOutAmount2); 

        // giving a different doa ID 
        vm.expectRevert("can't vote for multiple daos");
        knightingRound.buy(10e8, 1, emptyProof);
        assertEq(knightingRound.totalTokenIn(),2e8); // totelTokenIn should be same
        assertEq(knightingRound.daoVotedFor(shrimp), 0); // daoVotedFor should be same

        vm.stopPrank();
        
        // Knighting round concludes...
        vm.warp(knightingRoundParams.start + knightingRoundParams.duration);

        // Can't buy after round ends
        vm.startPrank(shark);
        vm.expectRevert("KnightingRound: already ended");
        knightingRound.buy(1e8, 0, emptyProof);
        vm.stopPrank();
    }
    

    
}
