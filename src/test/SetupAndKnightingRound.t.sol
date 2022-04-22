// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "../interfaces/badger/IBadgerVipGuestlist.sol";

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

        uint256 tokenOutAmount2 = knightingRound.buy(1e8, 0, emptyProof);
        assertEq(knightingRound.totalTokenIn(),2e8); // should increment
        assertEq(knightingRound.totalTokenOutBought(), tokenOutAmount + tokenOutAmount2);


        // giving a different doa ID
        vm.expectRevert("can't vote for multiple daos");
        knightingRound.buy(10e8, 1, emptyProof);
        assertEq(knightingRound.totalTokenIn(),2e8); // totelTokenIn should be same
        assertEq(knightingRound.daoVotedFor(shrimp), 0); // daoVotedFor should be same

        vm.stopPrank();

        // changing the token out price in mid sale
        vm.prank(governance);
        knightingRound.setTokenOutPrice(25e18);

        vm.prank(shrimp);
        uint256 newTokenAmountOut = knightingRound.buy(1e8, 0, emptyProof);

        // 21e18 is old price and 25e18 is new price
        uint256 newTokenAmountOutExpected = (tokenOutAmount * 25e18)/21e18;

        assertEq(newTokenAmountOut, newTokenAmountOutExpected);
        // Knighting round concludes...
        vm.warp(knightingRoundParams.start + knightingRoundParams.duration);

        // Can't buy after round ends
        vm.startPrank(shark);
        vm.expectRevert("KnightingRound: already ended");
        knightingRound.buy(1e8, 0, emptyProof);
        vm.stopPrank();
    }

    function testFinalizeAndClaim() public{
        bytes32[] memory emptyProof = new bytes32[](1);

        vm.warp(knightingRoundParams.start);

        vm.expectRevert("sale not finalized");
        knightingRound.claim();

        vm.startPrank(shrimp);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shrimp));
        uint256 tokenOutAmount = knightingRound.buy(1e8, 0, emptyProof); // shrimp bought something

        vm.stopPrank();

        vm.startPrank(governance);

        vm.expectRevert("KnightingRound: not finished");
        knightingRound.finalize();

        // move forward so that KnightingRound is finished.
        vm.warp(knightingRoundParams.start + knightingRoundParams.duration); // to saleEnded() true

        vm.expectRevert("KnightingRound: not enough balance");
        knightingRound.finalize();

        uint256 citadelBought = knightingRound.totalTokenOutBought();
        // Amount bought = 60% of initial supply, therefore total citadel ~= 1.67 amount bought.
        uint256 initialSupply = (citadelBought * 1666666666666666667) / 1e18;

        // Let's transfer citadel to kinghtingRound so that users can claim their bought citadel.
        citadel.mint(governance, initialSupply);
        citadel.transfer(address(knightingRound), citadelBought);
        knightingRound.finalize(); // round finalized
        vm.stopPrank();


        vm.startPrank(shrimp);
        comparator.snapPrev();
        knightingRound.claim();   // now shrimp can claim
        comparator.snapCurr();

        assertEq(comparator.diff("citadel.balanceOf(shrimp)"), tokenOutAmount);

        assertTrue(knightingRound.hasClaimed(shrimp)); // hasClaimed should be true

        // should not be able to claim again
        vm.expectRevert("already claimed");
        knightingRound.claim();

        vm.stopPrank();

        // shark did not buy anything
        vm.prank(shark);
        vm.expectRevert("nothing to claim");
        knightingRound.claim();

    }

    function testSetSaleStart() public{

        // tests for setStartSale function

        uint256 startTime = block.timestamp + 200;
        uint256 startTimePast = block.timestamp - 200 ;

        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setSaleStart(startTime);

        // check if it is same as set in BaseFixture
        assertEq(knightingRound.saleStart(), knightingRoundParams.start);

        // calling with correct role
        vm.startPrank(governance);
        knightingRound.setSaleStart(startTime);

        // check if saleStart is updated
        assertEq(knightingRound.saleStart(), startTime);

        vm.expectRevert("KnightingRound: start date may not be in the past");
        knightingRound.setSaleStart(startTimePast);

        // check if saleStart is not updated
        assertEq(knightingRound.saleStart(), startTime);

        // move forward to end the sale
        vm.warp(knightingRound.saleStart()+knightingRoundParams.duration);

        knightingRound.finalize();

        // can't set sale start after round is finished
        vm.expectRevert("KnightingRound: already finalized");
        knightingRound.setSaleStart(block.timestamp + 100);

        vm.stopPrank();

    }

    function setSaleDuration() public{
        // tests for setSaleDuration function

        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setSaleDuration(8 days);

        // check if it is same as set in BaseFixture
        assertEq(knightingRound.saleDuration(), knightingRoundParams.duration);

        // calling with correct role
        vm.startPrank(governance);
        knightingRound.setSaleDuration(8 days);

        // check if saleDuration is updated
        assertEq(knightingRound.saleDuration(), 8 days);

        vm.expectRevert("KnightingRound: the sale duration must not be zero");
        knightingRound.setSaleDuration(0);

        // check if saleDuration is not updated
        assertEq(knightingRound.saleDuration(), 8 days);

        // move forward to end the sale
        vm.warp(knightingRound.saleStart()+knightingRoundParams.duration);

        knightingRound.finalize();

        // can't set saleDuration after round is finished
        vm.expectRevert("KnightingRound: already finalized");
        knightingRound.setSaleDuration(2 days);

        // check if saleDuration is not updated
        assertEq(knightingRound.saleDuration(), 8 days);

        vm.stopPrank();
    }

    function testSetTokenInLimit() public{
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setTokenInLimit(25e18);

        // check if it is same as set in BaseFixture
        assertEq(knightingRound.tokenInLimit(), knightingRoundParams.wbtcLimit);

        // calling with correct role
        vm.startPrank(techOps);
        knightingRound.setTokenInLimit(25e18);

        // check if tokenInLimit is updated
        assertEq(knightingRound.tokenInLimit(), 25e18);

        vm.stopPrank();

        // move forward to end the sale
        vm.warp(knightingRound.saleStart()+knightingRoundParams.duration);

        vm.prank(governance);
        knightingRound.finalize();

        vm.prank(techOps);
        // can't set tokenInLimit after round is finished
        vm.expectRevert("KnightingRound: already finalized");
        knightingRound.setTokenInLimit(20e18);
    }

    function testBasicSetFunctions() public{

        // tests for setTokenOutPrice
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setTokenOutPrice(25e18);

        // check if it is same as set in BaseFixture
        assertEq(knightingRound.tokenOutPrice(), knightingRoundParams.citadelWbtcPrice);

        // calling with correct role
        vm.startPrank(governance);
        knightingRound.setTokenOutPrice(25e18);

        // check if tokenOutPrice is updated
        assertEq(knightingRound.tokenOutPrice(), 25e18);

        vm.expectRevert("KnightingRound: the price must not be zero");
        knightingRound.setTokenOutPrice(0);

        // check if tokenOutPrice is not updated
        assertEq(knightingRound.tokenOutPrice(), 25e18);

        // tests for setSaleRecipient
        knightingRound.setSaleRecipient(address(2));
        assertEq(knightingRound.saleRecipient(), address(2)); // check if SaleRecipient is set

        vm.expectRevert("KnightingRound: sale recipient should not be zero");
        knightingRound.setSaleRecipient(address(0));

        vm.stopPrank();

        // calling from different account
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setSaleRecipient(address(2));

        // tests for setGuestlist
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setGuestlist(address(3));

        vm.prank(techOps);
        knightingRound.setGuestlist(address(3));

        assertEq(address(knightingRound.guestlist()), address(3));

    }

    function testSweep() public{
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.sweep(address(citadel));

        vm.prank(treasuryOps);
        vm.expectRevert("nothing to sweep");
        knightingRound.sweep(address(citadel));

        // giving some citadel to knightingRound so that can be transfer to saleRecipient in sweep
        vm.prank(governance);
        citadel.mint(address(knightingRound), 1e18);

        address saleRecipient = knightingRound.saleRecipient();

        uint256 prevBalance = citadel.balanceOf(saleRecipient);
        vm.prank(treasuryOps);
        knightingRound.sweep(address(citadel));

        uint256 afterBalance = citadel.balanceOf(saleRecipient);

        // the difference should be 1e18
        assertEq(afterBalance - prevBalance, 1e18);

    }
}
