// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import "../interfaces/badger/IBadgerVipGuestlist.sol";

contract GuestlistTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testGuestListManualFlow() public {
        bytes32[] memory emptyProof = new bytes32[](0);

        // Only techOps can set GuestRoot
        vm.prank(rando);
        vm.expectRevert("GAC: invalid-caller-role");
        guestList.setGuestRoot(bytes32("random"));

        // Set a random guestRoot to "enable" guestlist
        vm.prank(techOps);
        guestList.setGuestRoot(bytes32("random"));

        // Start Knighting Round
        _setupKnightRound();

        // With a guestRoot and no valid proofs, users, not added manually, can't buy
        vm.startPrank(shark);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shark));
        vm.expectRevert("not authorized");
        knightingRound.buy(1e8, 0, emptyProof);
        vm.stopPrank();

        // User is added manually to the guestlist
        address[] memory guests = new address[](1);
        bool[] memory invitations = new bool[](1);
        guests[0] = shark;
        invitations[0] = true;

        vm.prank(techOps);
        guestList.setGuests(guests, invitations);

        // User, added manually, can buy
        vm.prank(shark);
        uint256 amountOut = knightingRound.buy(1e8, 0, emptyProof);
        require(amountOut > 0, "Buy unsuccessful");

        // Manually removing user from guestlist
        invitations[0] = false;
        vm.prank(techOps);
        guestList.setGuests(guests, invitations);

        // Removed user can't deposit anymore
        vm.prank(shark);
        vm.expectRevert("not authorized");
        knightingRound.buy(1e8, 0, emptyProof);
    }

    function testGuestListMerkleFlow() public {
        // Merkle test data
        bytes32 root = 0xc8eb7b9a26b0681320a4f6db1c93891f573fa496b6a99653f11cba4616899027;
        bytes32[] memory emptyProof = new bytes32[](0);

        address user1 = 0x6D3Ee34A020e7565e78540C74300218104C8e4a9;
        bytes32[] memory user1_proof = new bytes32[](11);
        // Assiging dynamically because function expects a dynamically sized array
        user1_proof[0] = bytes32(
            0x7e642443461a19363a2262ebeb0f861461d246a1df1410e36a56f81a303a61d7
        );
        user1_proof[1] = bytes32(
            0x290ed5a7b68bcd95f6ed8e136e2a0335d6cade78450b018ec8bb946ac15b8803
        );
        user1_proof[2] = bytes32(
            0x69ba581dd0b2fba6045504ae875cca9a10deab15085bd1865502b056626c92be
        );
        user1_proof[3] = bytes32(
            0xf8c46b8d0b30a8b4b9e4e07fd75989218167806fb87d21137c6f910fa9d13684
        );
        user1_proof[4] = bytes32(
            0xaafe989cc1b652283b764f4d8e5a08e8272eb95a9dc3722a677c93557b2b3a74
        );
        user1_proof[5] = bytes32(
            0x9f55639f22ada6a30c36ba41812d963b80ab60b33cdeff64658f696330e55844
        );
        user1_proof[6] = bytes32(
            0xf565c18009395df2293275976481508c33a11f13922581d036cd09533a3bc1ae
        );
        user1_proof[7] = bytes32(
            0x1bb36e9226e33ff930484e467b0aaa0e3fac1f498d5cb57a7ec3ead58ab1a087
        );
        user1_proof[8] = bytes32(
            0xd6aec7180836100f0a6c10929e02e0dda1f4a117d6368ddef6e7210302c74675
        );
        user1_proof[9] = bytes32(
            0xc262f8edb842d4953bb6c5df6178315e3d763890292a53210c99c36dd7a7a9bb
        );
        user1_proof[10] = bytes32(
            0x477817bd252134c4213e1dcb56f0c40608cb264ea7191730417452086dd7066c
        );

        // Mint assets for test user
        erc20utils.forceMintTo(user1, address(wbtc), 100e8);

        // Set a random guestRoot to "enable" guestlist
        vm.prank(techOps);
        guestList.setGuestRoot(root);

        // Start Knighting Round
        _setupKnightRound();

        // With a guestRoot, and no valid proofs, user can't buy
        vm.startPrank(user1);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(user1));
        vm.expectRevert("not authorized");
        knightingRound.buy(1e8, 0, emptyProof);

        // Using a valid proof allows user to buy
        uint256 amountOut = knightingRound.buy(1e8, 0, user1_proof);
        require(amountOut > 0, "Buy unsuccessful");

        // User, with a valid proof, can prove invitation and buy without using the proof
        guestList.proveInvitation(user1, user1_proof);
        amountOut = knightingRound.buy(1e8, 0, emptyProof);
        require(amountOut > 0, "Buy unsuccessful");

        vm.stopPrank();
    }

    function testEthGuestListManualFlow() public {
        bytes32[] memory emptyProof = new bytes32[](0);

        // Only techOps can set GuestRoot
        vm.prank(rando);
        vm.expectRevert("GAC: invalid-caller-role");
        guestList.setGuestRoot(bytes32("random"));

        // Set a random guestRoot to "enable" guestlist
        vm.prank(techOps);
        guestList.setGuestRoot(bytes32("random"));

        // Start Knighting Round
        _setupKnightRound();

        // With a guestRoot and no valid proofs, users, not added manually, can't buy
        vm.startPrank(shark);
        weth.approve(address(knightingRoundWithEth), address(shark).balance);
        vm.expectRevert("not authorized");
        knightingRoundWithEth.buyEth{value: 1 ether}(0, emptyProof);
        vm.stopPrank();

        // User is added manually to the guestlist
        address[] memory guests = new address[](1);
        bool[] memory invitations = new bool[](1);
        guests[0] = shark;
        invitations[0] = true;

        vm.prank(techOps);
        guestList.setGuests(guests, invitations);

        // User, added manually, can buy
        vm.prank(shark);
        uint256 amountOut = knightingRoundWithEth.buyEth{value: 1 ether}(
            0,
            emptyProof
        );
        require(amountOut > 0, "Buy unsuccessful");

        // Manually removing user from guestlist
        invitations[0] = false;
        vm.prank(techOps);
        guestList.setGuests(guests, invitations);

        // Removed user can't deposit anymore
        vm.prank(shark);
        vm.expectRevert("not authorized");
        knightingRoundWithEth.buyEth{value: 1 ether}(0, emptyProof);
    }

    function testEthGuestListMerkleFlow() public {
        // Merkle test data
        bytes32 root = 0xc8eb7b9a26b0681320a4f6db1c93891f573fa496b6a99653f11cba4616899027;
        bytes32[] memory emptyProof = new bytes32[](0);

        address user1 = 0x6D3Ee34A020e7565e78540C74300218104C8e4a9;
        bytes32[] memory user1_proof = new bytes32[](11);
        // Assiging dynamically because function expects a dynamically sized array
        user1_proof[0] = bytes32(
            0x7e642443461a19363a2262ebeb0f861461d246a1df1410e36a56f81a303a61d7
        );
        user1_proof[1] = bytes32(
            0x290ed5a7b68bcd95f6ed8e136e2a0335d6cade78450b018ec8bb946ac15b8803
        );
        user1_proof[2] = bytes32(
            0x69ba581dd0b2fba6045504ae875cca9a10deab15085bd1865502b056626c92be
        );
        user1_proof[3] = bytes32(
            0xf8c46b8d0b30a8b4b9e4e07fd75989218167806fb87d21137c6f910fa9d13684
        );
        user1_proof[4] = bytes32(
            0xaafe989cc1b652283b764f4d8e5a08e8272eb95a9dc3722a677c93557b2b3a74
        );
        user1_proof[5] = bytes32(
            0x9f55639f22ada6a30c36ba41812d963b80ab60b33cdeff64658f696330e55844
        );
        user1_proof[6] = bytes32(
            0xf565c18009395df2293275976481508c33a11f13922581d036cd09533a3bc1ae
        );
        user1_proof[7] = bytes32(
            0x1bb36e9226e33ff930484e467b0aaa0e3fac1f498d5cb57a7ec3ead58ab1a087
        );
        user1_proof[8] = bytes32(
            0xd6aec7180836100f0a6c10929e02e0dda1f4a117d6368ddef6e7210302c74675
        );
        user1_proof[9] = bytes32(
            0xc262f8edb842d4953bb6c5df6178315e3d763890292a53210c99c36dd7a7a9bb
        );
        user1_proof[10] = bytes32(
            0x477817bd252134c4213e1dcb56f0c40608cb264ea7191730417452086dd7066c
        );

        // Mint assets for test user
        vm.deal(user1, 100 ether);

        // Set a random guestRoot to "enable" guestlist
        vm.prank(techOps);
        guestList.setGuestRoot(root);

        // Start Knighting Round
        _setupKnightRound();

        // With a guestRoot, and no valid proofs, user can't buy
        vm.startPrank(user1);
        weth.approve(address(knightingRoundWithEth), address(user1).balance);
        vm.expectRevert("not authorized");
        knightingRoundWithEth.buyEth{value: 1 ether}(0, emptyProof);

        // Using a valid proof allows user to buy
        uint256 amountOut = knightingRoundWithEth.buyEth{value: 1 ether}(
            0,
            user1_proof
        );
        require(amountOut > 0, "Buy unsuccessful");

        // User, with a valid proof, can prove invitation and buy without using the proof
        guestList.proveInvitation(user1, user1_proof);
        amountOut = knightingRoundWithEth.buyEth{value: 1 ether}(0, emptyProof);
        require(amountOut > 0, "Buy unsuccessful");

        vm.stopPrank();
    }

    function _setupKnightRound() internal {
        // Move to knighting round start
        vm.warp(block.timestamp + 100);
    }
}
