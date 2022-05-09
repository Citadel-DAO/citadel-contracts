// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "../interfaces/badger/IBadgerVipGuestlist.sol";

interface WETH {
    function deposit() external payable;
}

contract KnightingRoundWithEthTest is BaseFixture {
    event Sale(
        address indexed buyer,
        uint8 indexed daoId,
        uint256 amountIn,
        uint256 amountOut
    );
    event Claim(address indexed claimer, uint256 amount);
    event TokenOutPerTokenInUpdated(uint256 tokenOutPerTokenIn);
    event SaleRecipientUpdated(address indexed recipient);

    function setUp() public override {
        BaseFixture.setUp();
    }

    function testKnightingRoundWithEthIntegration() public {
        bytes32[] memory emptyProof = new bytes32[](0);

        // Attempt to deposit before knighting round start
        vm.startPrank(shark);
        weth.approve(address(knightingRoundWithEth), address(shark).balance);
        vm.expectRevert("KnightingRound: not started");
        knightingRoundWithEth.buyEth{value: 1e18}(0, emptyProof);
        vm.stopPrank();

        // Move to knighting round start
        vm.warp(block.timestamp + 100);

        // Users deposit assets
        vm.startPrank(shrimp);

        vm.expectRevert("_tokenInAmount should be > 0");
        knightingRoundWithEth.buyEth{value: 0 ether}(0, emptyProof);

        comparator.snapPrev();

        uint256 tokenOutAmountExpected = (1e18 *
            knightingRoundWithEth.tokenOutPerTokenIn()) /
            knightingRoundWithEth.tokenInNormalizationValue();
        weth.approve(address(knightingRoundWithEth), type(uint256).max);

        vm.expectEmit(true, true, true, true);
        emit Sale(shrimp, 0, 1e18, tokenOutAmountExpected);
        uint256 tokenOutAmount = knightingRoundWithEth.buyEth{value: 1e18}(
            0,
            emptyProof
        );
        comparator.snapCurr();

        assertEq(knightingRoundWithEth.totalTokenIn(), 1e18); // totalTokenIn should be equal to deposit
        assertEq(tokenOutAmount, tokenOutAmountExpected); // transferred amount should be equal to expected
        assertEq(knightingRoundWithEth.totalTokenOutBought(), tokenOutAmount);
        assertEq(knightingRoundWithEth.daoVotedFor(shrimp), 0); // daoVotedFor should be set

        assertEq(comparator.negDiff("weth.balanceOf(shrimp)"), 0);
        assertEq(
            comparator.diff("knightingRoundWithEth.boughtAmounts(shrimp)"),
            21e18
        );

        // tokenInLimit = 100e8 so transaction should revert
        vm.expectRevert("total amount exceeded");
        vm.deal(address(shrimp), 1000e18);
        knightingRoundWithEth.buyEth{value: 1000e18}(0, emptyProof);
        assertEq(knightingRoundWithEth.totalTokenIn(), 1e18); // totelTokenIn should be same

        // buying again
        vm.expectEmit(true, true, true, true);
        emit Sale(
            shrimp,
            0,
            1e18,
            tokenOutAmountExpected // Same amount out since price is unmodified
        );
        uint256 tokenOutAmount2 = knightingRoundWithEth.buyEth{value: 1e18}(
            0,
            emptyProof
        );
        assertEq(knightingRoundWithEth.totalTokenIn(), 2e18); // should increment
        assertEq(
            knightingRoundWithEth.totalTokenOutBought(),
            tokenOutAmount + tokenOutAmount2
        );

        // giving a different doa ID
        vm.expectRevert("can't vote for multiple daos");
        knightingRoundWithEth.buyEth{value: 10e18}(1, emptyProof);
        assertEq(knightingRoundWithEth.totalTokenIn(), 2e18); // totelTokenIn should be same
        assertEq(knightingRoundWithEth.daoVotedFor(shrimp), 0); // daoVotedFor should be same

        vm.stopPrank();

        // changing the token out price in mid sale
        vm.prank(governance);
        knightingRoundWithEth.setTokenOutPerTokenIn(25e18);
        assertEq(knightingRoundWithEth.tokenOutPerTokenIn(), 25e18);

        // 21e18 is old price and 25e18 is new price
        uint256 newTokenAmountOutExpected = (tokenOutAmount * 25e18) / 21e18;

        vm.startPrank(shrimp);
        vm.expectEmit(true, true, true, true);
        emit Sale(shrimp, 0, 1e18, newTokenAmountOutExpected);
        uint256 newTokenAmountOut = knightingRoundWithEth.buyEth{value: 1e18}(
            0,
            emptyProof
        );
        vm.stopPrank();

        assertEq(newTokenAmountOut, newTokenAmountOutExpected);
        // Knighting round concludes...
        vm.warp(
            knightingRoundWithEthParams.start +
                knightingRoundWithEthParams.duration
        );

        // Can't buy after round ends
        vm.startPrank(shark);
        vm.expectRevert("KnightingRound: already ended");
        knightingRoundWithEth.buyEth{value: 1e18}(0, emptyProof);
        vm.stopPrank();
    }

    function testFinalizeAndClaimWithEth() public {
        bytes32[] memory emptyProof = new bytes32[](0);

        vm.warp(knightingRoundWithEthParams.start);

        vm.expectRevert("sale not finalized");
        knightingRoundWithEth.claim();

        vm.startPrank(shrimp);
        weth.approve(address(knightingRoundWithEth), type(uint256).max);

        uint256 tokenOutAmount = knightingRoundWithEth.buyEth{value: 1e18}(
            0,
            emptyProof
        ); // shrimp bought something

        vm.stopPrank();

        vm.startPrank(governance);

        vm.expectRevert("KnightingRound: not finished");
        knightingRoundWithEth.finalize();

        // move forward so that KnightingRound is finished.
        vm.warp(
            knightingRoundWithEthParams.start +
                knightingRoundWithEthParams.duration
        ); // to saleEnded() true

        vm.expectRevert("KnightingRound: not enough balance");
        knightingRoundWithEth.finalize();

        uint256 citadelBought = knightingRoundWithEth.totalTokenOutBought();
        // Amount bought = 60% of initial supply, therefore total citadel ~= 1.67 amount bought.
        uint256 initialSupply = (citadelBought * 1666666666666666667) / 1e18;

        // Let's transfer citadel to kinghtingRound so that users can claim their bought citadel.
        citadel.mint(governance, initialSupply);
        citadel.transfer(address(knightingRoundWithEth), citadelBought);
        knightingRoundWithEth.finalize(); // round finalized
        vm.stopPrank();

        vm.startPrank(shrimp);
        comparator.snapPrev();
        vm.expectEmit(true, true, true, true);
        emit Claim(shrimp, tokenOutAmount);
        knightingRoundWithEth.claim(); // now shrimp can claim
        comparator.snapCurr();

        assertEq(comparator.diff("citadel.balanceOf(shrimp)"), tokenOutAmount);

        assertTrue(knightingRoundWithEth.hasClaimed(shrimp)); // hasClaimed should be true

        // should not be able to claim again
        vm.expectRevert("already claimed");
        knightingRoundWithEth.claim();

        vm.stopPrank();

        // shark did not buy anything
        vm.prank(shark);
        vm.expectRevert("nothing to claim");
        knightingRoundWithEth.claim();
    }

    function testSetSaleStartWithEth() public {
        // tests for setStartSale function

        uint256 startTime = block.timestamp + 200;
        uint256 startTimePast = block.timestamp - 200;

        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRoundWithEth.setSaleStart(startTime);

        // check if it is same as set in BaseFixture
        assertEq(
            knightingRoundWithEth.saleStart(),
            knightingRoundWithEthParams.start
        );

        // calling with correct role
        vm.startPrank(governance);
        knightingRoundWithEth.setSaleStart(startTime);

        // check if saleStart is updated
        assertEq(knightingRoundWithEth.saleStart(), startTime);

        vm.expectRevert("KnightingRound: start date may not be in the past");
        knightingRoundWithEth.setSaleStart(startTimePast);

        // check if saleStart is not updated
        assertEq(knightingRoundWithEth.saleStart(), startTime);

        // move forward to end the sale
        vm.warp(
            knightingRoundWithEth.saleStart() +
                knightingRoundWithEthParams.duration
        );

        knightingRoundWithEth.finalize();

        // can't set sale start after round is finished
        vm.expectRevert("KnightingRound: already finalized");
        knightingRoundWithEth.setSaleStart(block.timestamp + 100);

        vm.stopPrank();
    }

    function testSetSaleDurationWithEth() public {
        // tests for setSaleDuration function
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRoundWithEth.setSaleDuration(8 days);

        // check if it is same as set in BaseFixture
        assertEq(
            knightingRoundWithEth.saleDuration(),
            knightingRoundWithEthParams.duration
        );

        // calling with correct role
        vm.startPrank(governance);
        knightingRoundWithEth.setSaleDuration(8 days);

        // check if saleDuration is updated
        assertEq(knightingRoundWithEth.saleDuration(), 8 days);

        vm.expectRevert("KnightingRound: the sale duration must not be zero");
        knightingRoundWithEth.setSaleDuration(0);

        // check if saleDuration is not updated
        assertEq(knightingRoundWithEth.saleDuration(), 8 days);

        // move forward to end of original sale
        vm.warp(
            knightingRoundWithEth.saleStart() +
                knightingRoundWithEthParams.duration
        );

        // Atttempt to finilize reverts due to extended duration
        require(
            !knightingRoundWithEth.saleEnded(),
            "Sale ended before expected!"
        );
        vm.expectRevert("KnightingRound: not finished");
        knightingRoundWithEth.finalize();

        // Move forward to end of new duration
        vm.warp(
            knightingRoundWithEth.saleStart() +
                knightingRoundWithEth.saleDuration()
        );

        // Sale is finilized
        knightingRoundWithEth.finalize();

        // can't set saleDuration after round is finished
        vm.expectRevert("KnightingRound: already finalized");
        knightingRoundWithEth.setSaleDuration(2 days);

        // check if saleDuration is not updated
        assertEq(knightingRoundWithEth.saleDuration(), 8 days);

        vm.stopPrank();
    }

    function testSetTokenInLimitWithEth() public {
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRoundWithEth.setTokenInLimit(25e18);

        // check if it is same as set in BaseFixture
        assertEq(
            knightingRoundWithEth.tokenInLimit(),
            knightingRoundWithEthParams.tokenInLimit
        );

        // calling with correct role
        vm.startPrank(techOps);
        knightingRoundWithEth.setTokenInLimit(25e18);

        // check if tokenInLimit is updated
        assertEq(knightingRoundWithEth.tokenInLimit(), 25e18);

        vm.stopPrank();

        // Move to knighting round start
        vm.warp(block.timestamp + 100);

        // End sale by depositing the limit amount
        require(
            !knightingRoundWithEth.saleEnded(),
            "Sale ended before expected!"
        );
        bytes32[] memory emptyProof = new bytes32[](0);
        vm.startPrank(shark);
        weth.approve(address(knightingRoundWithEth), type(uint256).max);
        knightingRoundWithEth.buyEth{value: 25e18}(0, emptyProof);
        vm.stopPrank();
        require(
            knightingRoundWithEth.saleEnded(),
            "Sale didn't ended when expected!"
        );

        // Mint citadel bought and finilize
        vm.startPrank(governance);
        uint256 citadelBought = knightingRoundWithEth.totalTokenOutBought();
        citadel.mint(address(knightingRoundWithEth), citadelBought);
        knightingRoundWithEth.finalize();
        vm.stopPrank();

        // can't set tokenInLimit after round is finished
        vm.prank(techOps);
        vm.expectRevert("KnightingRound: already finalized");
        knightingRoundWithEth.setTokenInLimit(20e18);
    }

    function testBasicSetFunctionsWithEth() public {
        // tests for setTokenOutPerTokenIn
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRoundWithEth.setTokenOutPerTokenIn(25e18);

        // check if it is same as set in BaseFixture
        assertEq(
            knightingRoundWithEth.tokenOutPerTokenIn(),
            knightingRoundWithEthParams.citadelWbtcPrice
        );

        // calling with correct role
        vm.startPrank(governance);
        vm.expectEmit(true, true, true, true);
        emit TokenOutPerTokenInUpdated(25e18);
        knightingRoundWithEth.setTokenOutPerTokenIn(25e18);

        // check if tokenOutPerTokenIn is updated
        assertEq(knightingRoundWithEth.tokenOutPerTokenIn(), 25e18);

        vm.expectRevert("KnightingRound: the price must not be zero");
        knightingRoundWithEth.setTokenOutPerTokenIn(0);

        // check if tokenOutPerTokenIn is not updated
        assertEq(knightingRoundWithEth.tokenOutPerTokenIn(), 25e18);

        // tests for setSaleRecipient
        vm.expectEmit(true, true, true, true);
        emit SaleRecipientUpdated(address(2));
        knightingRoundWithEth.setSaleRecipient(address(2));
        assertEq(knightingRoundWithEth.saleRecipient(), address(2)); // check if SaleRecipient is set

        vm.expectRevert("KnightingRound: sale recipient should not be zero");
        knightingRoundWithEth.setSaleRecipient(address(0));

        vm.stopPrank();

        // calling from different account
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRoundWithEth.setSaleRecipient(address(2));

        // tests for setGuestlist
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRoundWithEth.setGuestlist(address(3));

        vm.prank(techOps);
        knightingRoundWithEth.setGuestlist(address(3));

        assertEq(address(knightingRoundWithEth.guestlist()), address(3));
    }

    function testSweepWithEth() public {
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRoundWithEth.sweep(address(citadel));

        vm.prank(treasuryOps);
        vm.expectRevert("nothing to sweep");
        knightingRoundWithEth.sweep(address(citadel));

        // Mint 22 CTDL to the knightingRoundWithEth contract
        vm.prank(governance);
        citadel.mint(address(knightingRoundWithEth), 22e18);

        // Move to knighting round start
        vm.warp(block.timestamp + 100);

        // A user buys 21 CTDL with 1 WETH
        bytes32[] memory emptyProof = new bytes32[](0);
        vm.startPrank(shark);
        weth.approve(address(knightingRoundWithEth), type(uint256).max);
        knightingRoundWithEth.buyEth{value: 1e18}(0, emptyProof);
        vm.stopPrank();

        assertEq(knightingRoundWithEth.totalTokenOutBought(), 21e18); // 21 CTDL were bought at current price

        // treasuryOps should be able to sweep the leftover CTDL (22 on contract - 21 bought = 1 token)
        address saleRecipient = knightingRoundWithEth.saleRecipient();

        uint256 prevBalance = citadel.balanceOf(saleRecipient);
        vm.prank(treasuryOps);
        knightingRoundWithEth.sweep(address(citadel));

        uint256 afterBalance = citadel.balanceOf(saleRecipient);

        // the difference should be 1e18
        assertEq(afterBalance - prevBalance, 1e18);

        // treasuryOps should be able to sweep any amount of any token other than CTDL
        vm.deal(address(knightingRoundWithEth), 10e18);
        vm.prank(address(knightingRoundWithEth));
        WETH(weth_address).deposit{value: 10e18}();

        prevBalance = weth.balanceOf(saleRecipient);
        vm.prank(treasuryOps);
        knightingRoundWithEth.sweep(address(weth));

        afterBalance = weth.balanceOf(saleRecipient);

        // the difference should be 10e18
        assertEq(afterBalance - prevBalance, 10e18);
    }
}
