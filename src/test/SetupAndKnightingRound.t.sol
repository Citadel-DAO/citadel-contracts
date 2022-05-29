// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {KnightingRound} from "../KnightingRound.sol";
import "../interfaces/badger/IBadgerVipGuestlist.sol";
import "../interfaces/erc20/IERC20.sol";
import {SnapshotResolver} from "./SnapshotResolver.sol";

contract KnightingRoundTest is BaseFixture {
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

    SnapshotResolver resolver = new SnapshotResolver();

    function testKnightingRoundIntegration() public {
        bytes32[] memory emptyProof = new bytes32[](0);

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

        uint256 tokenOutAmountExpected = (1e8 *
            knightingRound.tokenOutPerTokenIn()) /
            knightingRound.tokenInNormalizationValue();
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shrimp));

        vm.expectEmit(true, true, true, true);
        emit Sale(shrimp, 0, 1e8, tokenOutAmountExpected);
        uint256 tokenOutAmount = knightingRound.buy(1e8, 0, emptyProof);
        comparator.snapCurr();

        assertEq(knightingRound.totalTokenIn(), 1e8); // totalTokenIn should be equal to deposit
        assertEq(tokenOutAmount, tokenOutAmountExpected); // transferred amount should be equal to expected
        assertEq(knightingRound.totalTokenOutBought(), tokenOutAmount);
        assertEq(knightingRound.daoVotedFor(shrimp), 0); // daoVotedFor should be set
        assertEq(knightingRound.daoCommitments(0), tokenOutAmount); // daoCommitments should be tokenOutAmount

        assertEq(comparator.negDiff("wbtc.balanceOf(shrimp)"), 1e8);
        assertEq(
            comparator.diff("knightingRound.boughtAmounts(shrimp)"),
            21e18
        );

        // tokenInLimit = 100e8 so transaction should revert
        vm.expectRevert("total amount exceeded");
        knightingRound.buy(100e8, 0, emptyProof);
        assertEq(knightingRound.totalTokenIn(), 1e8); // totelTokenIn should be same
        assertEq(knightingRound.daoCommitments(0), tokenOutAmount); // daoCommitments should be same

        // buying again
        vm.expectEmit(true, true, true, true);
        emit Sale(
            shrimp,
            0,
            1e8,
            tokenOutAmountExpected // Same amount out since price is unmodified
        );
        uint256 tokenOutAmount2 = knightingRound.buy(1e8, 0, emptyProof);
        assertEq(knightingRound.totalTokenIn(), 2e8); // should increment
        assertEq(
            knightingRound.totalTokenOutBought(),
            tokenOutAmount + tokenOutAmount2
        );
        assertEq(
            knightingRound.daoCommitments(0),
            tokenOutAmount + tokenOutAmount2
        ); // should increment

        // giving a different doa ID
        vm.expectRevert("can't vote for multiple daos");
        knightingRound.buy(10e8, 1, emptyProof);
        assertEq(knightingRound.totalTokenIn(), 2e8); // totelTokenIn should be same
        assertEq(knightingRound.daoVotedFor(shrimp), 0); // daoVotedFor should be same
        assertEq(knightingRound.daoCommitments(1), 0); // should be zero
        assertEq(
            knightingRound.daoCommitments(0),
            tokenOutAmount + tokenOutAmount2
        ); // should be same

        vm.stopPrank();

        vm.startPrank(whale);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(whale));
        uint256 tokenOutAmountWhale = knightingRound.buy(1e8, 1, emptyProof); // whale is voting for different dao
        assertEq(knightingRound.totalTokenIn(), 3e8); // totelTokenIn should increment
        assertEq(knightingRound.daoVotedFor(whale), 1); // daoVotedFor should be 1
        assertEq(knightingRound.daoCommitments(1), tokenOutAmountWhale); // should be tokenOutAmountWhale
        assertEq(
            knightingRound.daoCommitments(0),
            tokenOutAmount + tokenOutAmount2
        ); // should be same
        vm.stopPrank();

        // changing the token out price in mid sale
        vm.prank(governance);
        knightingRound.setTokenOutPerTokenIn(25e18);
        assertEq(knightingRound.tokenOutPerTokenIn(), 25e18);

        // 21e18 is old price and 25e18 is new price
        uint256 newTokenAmountOutExpected = (tokenOutAmount * 25e18) / 21e18;

        vm.startPrank(shrimp);
        vm.expectEmit(true, true, true, true);
        emit Sale(shrimp, 0, 1e8, newTokenAmountOutExpected);
        uint256 newTokenAmountOut = knightingRound.buy(1e8, 0, emptyProof);
        vm.stopPrank();

        assertEq(newTokenAmountOut, newTokenAmountOutExpected);
        // Knighting round concludes...
        vm.warp(knightingRoundParams.start + knightingRoundParams.duration);

        // Can't buy after round ends
        vm.startPrank(shark);
        vm.expectRevert("KnightingRound: already ended");
        knightingRound.buy(1e8, 0, emptyProof);
        vm.stopPrank();
    }

    function testMultipleKnightingRoundContract() public {
        KnightingRound knightingRound1 = new KnightingRound(); // wbtc
        KnightingRound knightingRound2 = new KnightingRound(); // cvx
        knightingRound1.initialize(
            address(gac),
            address(citadel),
            address(wbtc),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            21e18,
            address(governance),
            address(guestList),
            100e8
        );

        knightingRound2.initialize(
            address(gac),
            address(citadel),
            address(cvx),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            21e18,
            address(governance),
            address(guestList),
            100e18
        );

        wbtc.approve(address(knightingRound1), wbtc.balanceOf(shark));
        // Move to knighting round start
        vm.warp(block.timestamp + 100);

        buy(knightingRound1, wbtc, shark, 0, 1e8); // shark is voting dao 0 in 1st contract
        buy(knightingRound2, cvx, shark, 1, 1e18); // shark is voting dao 1 in 2nd contract
        buy(knightingRound1, wbtc, shark, 0, 2e8); // shark  is voting dao 0 in 1st contract again
        buy(knightingRound2, cvx, whale, 0, 2e18); // whale is voting dao 0 in 2nd contract
    }

    function testFinalizeAndClaim() public {
        bytes32[] memory emptyProof = new bytes32[](0);

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

        // Let's transfer xCitadel to kinghtingRound so that users can claim their bought citadel.
        citadel.mint(governance, initialSupply);
        citadel.approve(address(xCitadel), citadelBought);
        xCitadel.depositFor(address(knightingRound), citadelBought); // xCTDL 1:1 CTDL

        knightingRound.finalize(); // round finalized
        vm.stopPrank();

        vm.startPrank(shrimp);
        comparator.snapPrev();
        vm.expectEmit(true, true, true, true);
        emit Claim(shrimp, tokenOutAmount);
        knightingRound.claim(); // now shrimp can claim
        comparator.snapCurr();

        assertEq(comparator.diff("xCitadel.balanceOf(shrimp)"), tokenOutAmount);

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

    function testSetSaleStart() public {
        // tests for setStartSale function

        uint256 startTime = block.timestamp + 200;
        uint256 startTimePast = block.timestamp - 200;

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
        vm.warp(knightingRound.saleStart() + knightingRoundParams.duration);

        knightingRound.finalize();

        // can't set sale start after round is finished
        vm.expectRevert("KnightingRound: already finalized");
        knightingRound.setSaleStart(block.timestamp + 100);

        vm.stopPrank();
    }

    function testSetSaleDuration() public {
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

        // move forward to end of original sale
        vm.warp(knightingRound.saleStart() + knightingRoundParams.duration);

        // Atttempt to finilize reverts due to extended duration
        require(!knightingRound.saleEnded(), "Sale ended before expected!");
        vm.expectRevert("KnightingRound: not finished");
        knightingRound.finalize();

        // Move forward to end of new duration
        vm.warp(knightingRound.saleStart() + knightingRound.saleDuration());

        // Sale is finilized
        knightingRound.finalize();

        // can't set saleDuration after round is finished
        vm.expectRevert("KnightingRound: already finalized");
        knightingRound.setSaleDuration(2 days);

        // check if saleDuration is not updated
        assertEq(knightingRound.saleDuration(), 8 days);

        vm.stopPrank();
    }

    function testSetTokenInLimit() public {
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setTokenInLimit(25e8);

        // check if it is same as set in BaseFixture
        assertEq(
            knightingRound.tokenInLimit(),
            knightingRoundParams.tokenInLimit
        );

        // calling with correct role
        vm.startPrank(techOps);
        knightingRound.setTokenInLimit(25e8);

        // check if tokenInLimit is updated
        assertEq(knightingRound.tokenInLimit(), 25e8);

        vm.stopPrank();

        // Move to knighting round start
        vm.warp(block.timestamp + 100);

        // End sale by depositing the limit amount
        require(!knightingRound.saleEnded(), "Sale ended before expected!");
        bytes32[] memory emptyProof = new bytes32[](0);
        vm.startPrank(shark);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shark));
        knightingRound.buy(25e8, 0, emptyProof);
        vm.stopPrank();
        require(knightingRound.saleEnded(), "Sale didn't ended when expected!");

        // Mint citadel bought and finilize
        vm.startPrank(governance);
        uint256 citadelBought = knightingRound.totalTokenOutBought();
        citadel.mint(governance, citadelBought);
        citadel.approve(address(xCitadel), citadelBought);
        xCitadel.depositFor(address(knightingRound), citadelBought); // xCTDL 1:1 CTDL

        knightingRound.finalize();
        vm.stopPrank();

        // can't set tokenInLimit after round is finished
        vm.prank(techOps);
        vm.expectRevert("KnightingRound: already finalized");
        knightingRound.setTokenInLimit(20e18);
    }

    function testBasicSetFunctions() public {
        // tests for setTokenOutPerTokenIn
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setTokenOutPerTokenIn(25e18);

        // check if it is same as set in BaseFixture
        assertEq(
            knightingRound.tokenOutPerTokenIn(),
            knightingRoundParams.citadelWbtcPrice
        );

        // calling with correct role
        vm.startPrank(governance);
        vm.expectEmit(true, true, true, true);
        emit TokenOutPerTokenInUpdated(25e18);
        knightingRound.setTokenOutPerTokenIn(25e18);

        // check if tokenOutPerTokenIn is updated
        assertEq(knightingRound.tokenOutPerTokenIn(), 25e18);

        vm.expectRevert("KnightingRound: the price must not be zero");
        knightingRound.setTokenOutPerTokenIn(0);

        // check if tokenOutPerTokenIn is not updated
        assertEq(knightingRound.tokenOutPerTokenIn(), 25e18);

        // tests for setSaleRecipient
        vm.expectEmit(true, true, true, true);
        emit SaleRecipientUpdated(address(2));
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

    function testSweep() public {
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.sweep(address(xCitadel));

        vm.prank(treasuryOps);
        vm.expectRevert("nothing to sweep");
        knightingRound.sweep(address(xCitadel));

        // Mint 22 xCTDL to the knightingRound contract
        vm.startPrank(governance);
        citadel.mint(governance, 100e18);
        citadel.approve(address(xCitadel), 22e18);
        xCitadel.depositFor(address(knightingRound), 22e18); // xCTDL 1:1 CTDL
        vm.stopPrank();

        // Move to knighting round start
        vm.warp(block.timestamp + 100);

        // A user buys 21 xCTDL with 1 wBTC
        bytes32[] memory emptyProof = new bytes32[](0);
        vm.startPrank(shark);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shark));
        knightingRound.buy(1e8, 0, emptyProof);
        vm.stopPrank();

        assertEq(knightingRound.totalTokenOutBought(), 21e18); // 21 xCTDL were bought at current price

        // treasuryOps should be able to sweep the leftover CTDL (22 on contract - 21 bought = 1 token)
        address saleRecipient = knightingRound.saleRecipient();

        uint256 prevBalance = xCitadel.balanceOf(saleRecipient);
        vm.prank(treasuryOps);
        knightingRound.sweep(address(xCitadel));

        uint256 afterBalance = xCitadel.balanceOf(saleRecipient);

        // the difference should be 1e18
        assertEq(afterBalance - prevBalance, 1e18);

        // treasuryOps should be able to sweep any amount of any token other than xCTDL
        erc20utils.forceMintTo(address(knightingRound), address(wbtc), 10e8);

        prevBalance = wbtc.balanceOf(saleRecipient);
        vm.prank(treasuryOps);
        knightingRound.sweep(address(wbtc));

        afterBalance = wbtc.balanceOf(saleRecipient);

        // the difference should be 10e8
        assertEq(afterBalance - prevBalance, 10e8);
    }

    function buy(
        KnightingRound _knightingRound,
        IERC20 _tokenIn,
        address _buyer,
        uint8 _daoID,
        uint256 _amountIn
    ) public {
        bytes32[] memory emptyProof = new bytes32[](0);
        uint256 totalTokenIn = _knightingRound.totalTokenIn();
        uint256 daoCommitment = _knightingRound.daoCommitments(_daoID);
        vm.startPrank(_buyer);
        _tokenIn.approve(address(_knightingRound), _tokenIn.balanceOf(_buyer));
        uint256 tokenOutAmount = _knightingRound.buy(
            _amountIn,
            _daoID,
            emptyProof
        );
        assertEq(_knightingRound.totalTokenIn(), totalTokenIn + _amountIn); // totelTokenIn should increment
        assertEq(_knightingRound.daoVotedFor(_buyer), _daoID); // daoVotedFor should be _daoID
        assertEq(
            _knightingRound.daoCommitments(_daoID),
            daoCommitment + tokenOutAmount
        ); // daoCommitment should increment
        vm.stopPrank();
    }

    function prepareKnightingRoundBuy(
        address tokenIn,
        string memory tokenName,
        uint8 daoId
    ) public {
        comparator.addCall(
            string.concat(tokenName, ".balanceOf(saleRecipient)"),
            tokenIn,
            abi.encodeWithSignature(
                "balanceOf(address)",
                knightingRound.saleRecipient()
            )
        );
        comparator.addCall(
            "knightingRound.daoCommitments(daoId)",
            address(knightingRound),
            abi.encodeWithSignature("daoCommitments(uint8)", daoId)
        );
        comparator.addCall(
            "knightingRound.totalTokenIn()",
            address(knightingRound),
            abi.encodeWithSignature("totalTokenIn()")
        );
    }

    function postKnightingRound(uint256 amountIn, string memory tokenIn)
        public
    {
        uint256 tokenOutAmountExpected = (amountIn *
            knightingRound.tokenOutPerTokenIn()) /
            knightingRound.tokenInNormalizationValue();

        assertEq(
            comparator.diff(
                string.concat(tokenIn, ".balanceOf(saleRecipient)")
            ),
            amountIn
        );
        assertEq(
            comparator.diff("knightingRound.daoCommitments(daoId)"),
            tokenOutAmountExpected
        );
        assertEq(comparator.diff("knightingRound.totalTokenIn()"), amountIn);
    }

    function testBuy() public {
        // Move to knighting round start
        vm.warp(block.timestamp + 100);
        // add accounts to track
        prepareKnightingRoundBuy(address(wbtc), "wbtc", 0);
        comparator.snapPrev();
        bytes32[] memory emptyProof = new bytes32[](0);
        vm.startPrank(shrimp);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shrimp));
        knightingRound.buy(1e8, 0, emptyProof);
        comparator.snapCurr();
        // run checks after buy
        postKnightingRound(1e8, "wbtc");
    }
}
