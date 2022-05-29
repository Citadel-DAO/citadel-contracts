// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "ds-test/test.sol";

import {FundingRegistry} from "../FundingRegistry.sol";

contract FundingRegistryTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    FundingRegistry public fundingRegistry;

    function testKnightingRoundRegistryInitialization() public {
        fundingRegistry = new FundingRegistry();

        assertEq(address(0), fundingRegistry.gacAddress());
        assertEq(address(0), fundingRegistry.citadel());
        assertEq(address(0), fundingRegistry.xCitadel());
        assertEq(address(0), fundingRegistry.saleRecipient());
        assertEq(address(0), fundingRegistry.fundingImplementation());

        FundingRegistry.FundingAsset memory fundingAsset = FundingRegistry
            .FundingAsset(address(wbtc), address(medianOracleWbtc), 500 * 10e8);

        FundingRegistry.FundingAsset[]
            memory initFunds = new FundingRegistry.FundingAsset[](1);

        initFunds[0] = fundingAsset;

        vm.prank(address(governance));

        fundingRegistry.initialize(
            address(gac),
            address(citadel),
            address(xCitadel),
            address(treasuryVault),
            initFunds
        );
    }
}
