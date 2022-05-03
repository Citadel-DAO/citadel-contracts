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

        KnightingRoundRegistry.initParam
            memory wethParams = KnightingRoundRegistry.initParam(
                address(0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F),
                10e12,
                500 * 10e8
            );

        KnightingRoundRegistry.initParam[]
            memory roundParams = new KnightingRoundRegistry.initParam[](2);
        roundParams[0] = KnightingRoundRegistry.initParam(
            address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599),
            10e12,
            500 * 10e8
        );
        roundParams[1] = KnightingRoundRegistry.initParam(
            address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D),
            10e12,
            500 * 10e6
        );

        knightinRoundRegistry.initialize(
            address(gac),
            block.timestamp,
            address(citadel),
            treasuryVault,
            address(guestList),
            wethParams,
            roundParams
        );

        //assertEq(address(gac), knightinRoundRegistry.governance());
        //assertEq(address(citadel), knightinRoundRegistry.tokenOut());
        //assertEq(treasuryVault, knightinRoundRegistry.saleRecipient());
        //assertEq(address(guestList), knightinRoundRegistry.guestList());
        //assertEq(block.timestamp, knightinRoundRegistry.phaseOneStart());
        //assertTrue(
        //    address(0) != knightinRoundRegistry.knightingRoundImplementation()
        //);
        //assertTrue(
        //    address(0) !=
        //        knightinRoundRegistry.knightingRoundWithEthImplementation()
        //);
    }
}
