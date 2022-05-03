// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "ds-test/test.sol";

import {KnightingRoundRegistry} from "../KnightingRoundRegistry.sol";

contract KnightingRoundRegistryTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    KnightingRoundRegistry public knightinRoundRegistry;

    function testKnightingRoundRegistryInitialization() public {
        vm.prank(governance);

        knightinRoundRegistry = new KnightingRoundRegistry();

        assertEq(address(0), knightinRoundRegistry.governance());
        assertEq(address(0), knightinRoundRegistry.tokenOut());
        assertEq(address(0), knightinRoundRegistry.saleRecipient());
        assertEq(address(0), knightinRoundRegistry.guestList());
        assertEq(0, knightinRoundRegistry.phaseOneStart());
        assertEq(
            address(0),
            knightinRoundRegistry.knightingRoundImplementation()
        );
        assertEq(
            address(0),
            knightinRoundRegistry.knightingRoundWithEthImplementation()
        );

        knightinRoundRegistry.initialize(
            address(gac),
            block.timestamp,
            address(citadel),
            treasuryVault,
            address(guestList)
        );

        assertEq(address(gac), knightinRoundRegistry.governance());
        assertEq(address(citadel), knightinRoundRegistry.tokenOut());
        assertEq(treasuryVault, knightinRoundRegistry.saleRecipient());
        assertEq(address(guestList), knightinRoundRegistry.guestList());
        assertEq(block.timestamp, knightinRoundRegistry.phaseOneStart());
        assertTrue(
            address(0) != knightinRoundRegistry.knightingRoundImplementation()
        );
        assertTrue(
            address(0) !=
                knightinRoundRegistry.knightingRoundWithEthImplementation()
        );
    }
}
