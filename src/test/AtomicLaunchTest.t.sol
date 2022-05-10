pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {KnightingRound} from "../KnightingRound.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import "../interfaces/erc20/IERC20.sol";

contract AtomicLaunchTest is BaseFixture {
    using FixedPointMathLib for uint256;

    uint256 constant MAX_UINT256 = type(uint256).max;

    // NOTE: wBTC and wETH are handled on fixture
    KnightingRound knightingRound_cvx = new KnightingRound();
    KnightingRound knightingRound_renBTC = new KnightingRound();
    KnightingRound knightingRound_ibBTC = new KnightingRound();
    KnightingRound knightingRound_frax = new KnightingRound();
    KnightingRound knightingRound_ust = new KnightingRound();
    KnightingRound knightingRound_usdc = new KnightingRound();
    KnightingRound knightingRound_badger = new KnightingRound();
    KnightingRound knightingRound_bveCVX = new KnightingRound();

    function setUp() public override {
        BaseFixture.setUp();

        // There will be no tokenIn limit (Round can only finish based on time)
        vm.startPrank(techOps);
        knightingRound.setTokenInLimit(MAX_UINT256); // wBTC
        knightingRoundWithEth.setTokenInLimit(MAX_UINT256);
        vm.stopPrank();

        // Setup rounds with somehow realistic prices
        vm.startPrank(governance);
        knightingRound.setTokenOutPerTokenIn(1500e18); //1500 xCTDL per wBTC
        knightingRoundWithEth.setTokenOutPerTokenIn(115e18); // 115 xCTDL per ETH

        knightingRound_cvx.initialize(
            address(gac),
            address(xCitadel),
            address(cvx),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1e18, // 1 xCTDL per CVX
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        knightingRound_renBTC.initialize(
            address(gac),
            address(xCitadel),
            address(renBTC),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1500e18, // 1500 xCTDL per renBTC
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        knightingRound_ibBTC.initialize(
            address(gac),
            address(xCitadel),
            address(ibBTC),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1500e18, // 1500 xCTDL per ibBTC
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        knightingRound_frax.initialize(
            address(gac),
            address(xCitadel),
            address(frax),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            47619047610000000, // 0.0476 xCTDL per frax
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        knightingRound_ust.initialize(
            address(gac),
            address(xCitadel),
            address(ust),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            47619047610000000, // 0.0476 xCTDL per ust
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        knightingRound_usdc.initialize(
            address(gac),
            address(xCitadel),
            address(usdc),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            47619047610000000, // 0.0476 xCTDL per usdc
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        knightingRound_badger.initialize(
            address(gac),
            address(xCitadel),
            address(badger),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            333333333333333333, // 0.333 xCTDL per badger
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        knightingRound_bveCVX.initialize(
            address(gac),
            address(xCitadel),
            address(bveCVX),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1e18, // 1 xCTDL per bveCVX
            address(governance),
            address(guestList),
            MAX_UINT256
        );

        vm.stopPrank();
    }

    function testAtomicLaunch() public {
        require(true, "test setup");
    }

    // function emulateKnightingRound() {

    // }
}
