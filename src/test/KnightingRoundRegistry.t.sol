// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "ds-test/test.sol";

import {BaseFixture} from "./BaseFixture.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

import {KnightingRoundRegistry} from "../KnightingRoundRegistry.sol";

contract KnightingRoundRegistryTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    KnightingRoundRegistry public knightinRoundRegistry;

    function testKnightingRoundRegistryInitialization() public {
        knightinRoundRegistry = new KnightingRoundRegistry();

        assertEq(address(0), knightinRoundRegistry.governance);
        assertEq(address(0), knightinRoundRegistry.tokenOut);
        assertEq(address(0), knightinRoundRegistry.saleRecipient);
        assertEq(address(0), knightinRoundRegistry.guestList);
    }
}
