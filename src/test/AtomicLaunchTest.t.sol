pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import "../interfaces/erc20/IERC20.sol";

contract AtomicLaunchTest is BaseFixture {
    using FixedPointMathLib for uint256;

    uint256 constant MAX_UINT256 = uint256(-1);

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

        // There will be no token in limit (Round can only finish based on time)
        vm.startPrank(governance);
        knightingRound.setTokenInLimit(MAX_UINT256);

        // Setup rounds with someow realistic prices
    }

    function testAtomicLaunch() {

    }

    function emulateKnightingRound() {

    }
}
