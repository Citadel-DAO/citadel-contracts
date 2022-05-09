// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "ds-test/test.sol";
import "forge-std/console.sol";

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
        assertEq(address(0), knightinRoundRegistry.guestlist());
        assertEq(0, knightinRoundRegistry.roundStart());
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
                address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
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
            3 days,
            address(citadel),
            treasuryVault,
            address(guestList),
            wethParams,
            roundParams
        );

        //address wethRoundAddress = knightinRoundRegistry
        //    .knightingRoundImplementation();
        //address ethRoundAddress = knightinRoundRegistry
        //    .knightingRoundWithEthImplementation();

        assertEq(knightinRoundRegistry.getAllRounds().length, 4);

        address targetRoundAddress = knightinRoundRegistry.getAllRounds()[1];

        KnightingRoundRegistry.RoundData
            memory targetRound = knightinRoundRegistry.getRoundData(
                targetRoundAddress
            );

        assertEq(targetRound.roundAddress, address(targetRoundAddress));
        assertEq(targetRound.tokenOut, address(citadel));
        assertEq(
            targetRound.tokenIn,
            address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)
        );
        assertEq(targetRound.saleStart, block.timestamp);
        assertEq(targetRound.saleDuration, 3 days);
        assertTrue(targetRound.finalized == false);
        assertEq(targetRound.tokenOutPerTokenIn, 500 * 10e8);
        assertEq(targetRound.totalTokenIn, 0);
        assertEq(targetRound.totalTokenOutBought, 0);
        assertEq(targetRound.totalTokenOutClaimed, 0);
        assertEq(targetRound.tokenInLimit, 10e12);
        assertEq(targetRound.tokenInNormalizationValue, 10**8);
        assertEq(targetRound.guestlist, address(guestList));
        assertTrue(targetRound.isEth == false);

        KnightingRoundRegistry.RoundData
            memory wethRound = knightinRoundRegistry.getRoundData(
                knightinRoundRegistry.getAllRounds()[0]
            );

        assertEq(
            wethRound.roundAddress,
            knightinRoundRegistry.getAllRounds()[0]
        );
        assertEq(wethRound.tokenOut, address(citadel));
        assertEq(
            wethRound.tokenIn,
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        );
        assertEq(wethRound.saleStart, block.timestamp);
        assertEq(wethRound.saleDuration, 3 days);
        assertTrue(wethRound.finalized == false);
        assertEq(wethRound.tokenOutPerTokenIn, 500 * 10e8);
        assertEq(wethRound.totalTokenIn, 0);
        assertEq(wethRound.totalTokenOutBought, 0);
        assertEq(wethRound.totalTokenOutClaimed, 0);
        assertEq(wethRound.tokenInLimit, 10e12);
        assertEq(wethRound.tokenInNormalizationValue, 10**18);
        assertEq(wethRound.guestlist, address(guestList));
        assertTrue(wethRound.isEth == false);

        KnightingRoundRegistry.RoundData memory ethRound = knightinRoundRegistry
            .getRoundData(
                knightinRoundRegistry.getAllRounds()[3]
            );

        assertEq(
            ethRound.roundAddress,
            knightinRoundRegistry.getAllRounds()[3]
        );
        assertEq(ethRound.tokenOut, address(citadel));
        assertEq(
            ethRound.tokenIn,
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        );
        assertEq(ethRound.saleStart, block.timestamp);
        assertEq(ethRound.saleDuration, 3 days);
        assertTrue(ethRound.finalized == false);
        assertEq(ethRound.tokenOutPerTokenIn, 500 * 10e8);
        assertEq(ethRound.totalTokenIn, 0);
        assertEq(ethRound.totalTokenOutBought, 0);
        assertEq(ethRound.totalTokenOutClaimed, 0);
        assertEq(ethRound.tokenInLimit, 10e12);
        assertEq(ethRound.tokenInNormalizationValue, 10**18);
        assertEq(ethRound.guestlist, address(guestList));
        assertTrue(ethRound.isEth == true);

        KnightingRoundRegistry.RoundData[]
            memory roundsData = knightinRoundRegistry.getAllRoundsData();

        for (uint256 i = 0; i < roundsData.length; i++) {
            assertEq(roundsData[i].tokenOut, address(citadel));
            assertEq(roundsData[i].saleStart, block.timestamp);
            assertEq(roundsData[i].saleDuration, 3 days);
            assertTrue(roundsData[i].finalized == false);
            assertEq(roundsData[i].totalTokenIn, 0);
            assertEq(roundsData[i].totalTokenOutBought, 0);
            assertEq(roundsData[i].totalTokenOutClaimed, 0);
            assertEq(roundsData[i].guestlist, address(guestList));
        }
    }
}
