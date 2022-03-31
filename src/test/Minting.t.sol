// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract SupplyScheduleTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testExampleEpochRates() public {
        assertTrue(true);
        emit log("Epoch Rates");
        emit log_uint(schedule.epochRate(0));
        emit log_uint(schedule.epochRate(1));
        emit log_uint(schedule.epochRate(2));
        emit log_uint(schedule.epochRate(3));
        emit log_uint(schedule.epochRate(4));
        emit log_uint(schedule.epochRate(5));
        emit log_uint(schedule.epochRate(6));
    }

}
