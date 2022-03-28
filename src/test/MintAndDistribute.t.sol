// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract MintAndDistributeTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testMintAndDistribute() public {
        /*
            Flow:
            - policy ops pings minter with the proportions to go to funding, locking, staking (decided off-chain for now)
            - this can be called at any frequency (not sure on rounding impact at very fast rate such as per-block)
                - we could set a max frequency by governance when we move to permissionless here
            - minted amount should match from epoch data
            - epoch data should be sanity checked
            - should handle the case at the border of two epochs gracefully
            - if there is an undefined epoch, it should fail until that epoch is defined. 
                -  after this is corrected, it should mint as expected from last mint as if that data had been there.
            - the assets should end up in the proper places in the expected proprotions
                - xCitadel balance and ppfs going up
                - vlCitadel rewards data changing as expected
                - various funding contracts funding in expected proportions
                - test a few cases for adding and removing funding contracts

            There unfortunately is the daily manual step of the initial mint destination propotions, we can automate this via contract with some work and oracles.
        */

        vm.startPrank(policyOps);
        citadelMinter.setCitadelDistributionSplit(4000,3000,3000);
        // confirm only policy ops can call
        // bps between three positions must add up to 10000 (100%)

        // can't mint before start
        // vm.expectRevert("SupplySchedule: minting not started");

        // can't mint without funding pools setup
        vm.expectRevert("CitadelMinter: no funding pools");
        citadelMinter.mintAndDistribute();

        citadelMinter.setFundingPoolWeight(address(fundingWbtc), 8000);
        citadelMinter.setFundingPoolWeight(address(fundingCvx), 2000);
        
        // policy ops should not be able to start minting schedule
        vm.expectRevert("invalid-caller-role");
        schedule.setMintingStart(block.timestamp);

        vm.prank(governance);
        schedule.setMintingStart(block.timestamp);

        vm.warp(1000);

        vm.startPrank(policyOps);
        citadelMinter.mintAndDistribute();
        vm.stopPrank();
    }
}
