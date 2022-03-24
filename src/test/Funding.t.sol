// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract SetupAndKnightingRoundTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    fucntion testFundingFlow() public {
        /*
            Flow:
            - discount rate modulates gracefully

            Updating Oracle data:
            - handled by EOA in this test

            General:
            - permissioned calls are permissioned as expected
            - pausing works
            - events are emitted
            - values are sanity checked
        */
    }
}
