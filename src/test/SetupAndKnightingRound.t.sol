// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract SetupAndKnightingRoundTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    fucntion testKnightingRoundIntegration() public {
        // Users deposit assets

        // Knighting round concludes...

        /*
            Prepare for launch (atomic):
            - Mint initial Citadel based on knighting round assets raised
            - Send 60% to knighting round for distribution
            - finalize() KR to get assets
            - LP with 15% of citadel supply + wBTC amount as per initial price
            - Send 25% remaining to treasury vault
            - Initialize and open funding contracts

            [Citadel now has an open market and funding can commence!]
        */
    }
}
