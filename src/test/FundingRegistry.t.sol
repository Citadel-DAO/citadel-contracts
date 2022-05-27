// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "ds-test/test.sol";

import {FundingRegistry} from "../KnightingRoundRegistry.sol";

contract FundingRegistry is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }
}
