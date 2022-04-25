// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";
import {CitadelMinter} from "../CitadelMinter.sol";

contract MintingTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testSetCitadelDistributionSplit() public{
        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.setCitadelDistributionSplit(5000, 3000, 2000);

        vm.startPrank(policyOps);
        vm.expectRevert("CitadelMinter: Sum of propvalues must be 10000 bps");
        citadelMinter.setCitadelDistributionSplit(5000, 2000, 2000);

        citadelMinter.setCitadelDistributionSplit(5000, 3000, 2000);
        // check if distribution split is set.
        assertEq(citadelMinter.fundingBps(),5000);
        assertEq(citadelMinter.stakingBps(),3000);
        assertEq(citadelMinter.lockingBps(),2000);

        vm.stopPrank();

        // pausing should freeze setCitadelDistributionSplit
        vm.prank(guardian);
        gac.pause();
        vm.prank(address(policyOps));
        vm.expectRevert(bytes("global-paused"));
        citadelMinter.setCitadelDistributionSplit(5000, 3000, 2000);

    }

    function testSetFundingPoolWeight() public{
        _testSetFundingPoolWeight(address(fundingCvx), 8000);
        _testSetFundingPoolWeight(address(fundingWbtc), 2000);

        // check if totalFundingPoolWeight is updated
        assertEq(citadelMinter.totalFundingPoolWeight(), 10000);

        _testSetFundingPoolWeight(address(fundingCvx), 6000);
        // check if totalFundingPoolWeight is updated
        assertEq(citadelMinter.totalFundingPoolWeight(), 8000);
        // check if weight is more than MAX_BPS
        _testSetFundingPoolWeight(address(fundingCvx), 11000);

    }

    function testFundingPoolsMintingDistribution(uint _x, uint _y, uint _fundingWeight) public{
        uint MAX_BPS = 10000 ; 
        vm.assume(_x<=MAX_BPS && _y<=MAX_BPS && _fundingWeight<=MAX_BPS && (_x>0 || _y>0));

        vm.prank(policyOps);
        citadelMinter.setCitadelDistributionSplit(_fundingWeight, 10000 - _fundingWeight, 0); // Funding weight = 50%

        _testSetFundingPoolWeight(address(fundingCvx), _x);
        _testSetFundingPoolWeight(address(fundingWbtc), _y);

        uint fundingCvxPoolBalanceBefore = citadel.balanceOf(address(fundingCvx));
        uint fundingWbtcPoolBalanceBefore = citadel.balanceOf(address(fundingWbtc));

        uint mintedAmount = mintAndDistribute();

        uint fundingCvxPoolBalanceAfter = citadel.balanceOf(address(fundingCvx));
        uint fundingWbtcPoolBalanceAfter = citadel.balanceOf(address(fundingWbtc));

        uint fundingCvxReceived = fundingCvxPoolBalanceAfter-fundingCvxPoolBalanceBefore;
        uint fundingWbtcReceived = fundingWbtcPoolBalanceAfter-fundingWbtcPoolBalanceBefore;

        uint fundingAmount = (mintedAmount * _fundingWeight)/ MAX_BPS ; 
        emit log_named_uint("Funding Amount" , fundingAmount);
        uint totalFundingWeight = citadelMinter.totalFundingPoolWeight();
        // to avoid rounding errors instead of equal
        assertTrue(fundingAmount - (fundingCvxReceived+fundingWbtcReceived) < 10 );

        // fundingPool Received as expected
        assertEq(fundingCvxReceived, (fundingAmount*_x)/totalFundingWeight);
        assertEq(fundingWbtcReceived, (fundingAmount*_y)/totalFundingWeight);

    }

    function mintAndDistribute() public returns (uint) {
        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();

        vm.warp(block.timestamp + 1000);
        uint expectedMint = schedule.getMintable(citadelMinter.lastMintTimestamp());
        vm.prank(policyOps);
        citadelMinter.mintAndDistribute();

        return expectedMint ;
    }

    function _testSetFundingPoolWeight(address fundingPool, uint256 weight) public{
        vm.stopPrank();
        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.setFundingPoolWeight(fundingPool, weight);

        vm.startPrank(policyOps);
        if(weight > 10000){
            vm.expectRevert("exceed max funding pool weight");
            citadelMinter.setFundingPoolWeight(fundingPool , weight);
        }
        else{
            citadelMinter.setFundingPoolWeight(fundingPool , weight);
            assertEq(citadelMinter.fundingPoolWeights(fundingPool), weight);
        }
        vm.stopPrank();
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
