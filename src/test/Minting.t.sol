// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";
import {CitadelMinter} from "../CitadelMinter.sol";

contract MintingTest is BaseFixture {
    // To avoid "Stack to deep" error
    struct TestInfo {
        uint256 fundingCvxPoolBalanceBefore;
        uint256 fundingWbtcPoolBalanceBefore;
        uint256 stakingBalanceBefore;
        uint256 daoBalanceBefore;
        uint256 fundingCvxPoolBalanceAfter;
        uint256 fundingWbtcPoolBalanceAfter;
        uint256 stakingBalanceAfter;
        uint256 daoBalanceAfter;
    }

    function setUp() public override {
        BaseFixture.setUp();
    }

    function testSetCitadelDistributionSplit() public {
        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.setCitadelDistributionSplit(5000, 3000, 1000, 1000);

        vm.startPrank(policyOps);
        vm.expectRevert("CitadelMinter: Sum of propvalues must be 10000 bps");
        citadelMinter.setCitadelDistributionSplit(5000, 2000, 2000, 500);

        citadelMinter.setCitadelDistributionSplit(5000, 2500, 1000, 1500);
        // check if distribution split is set.
        assertEq(citadelMinter.fundingBps(), 5000);
        assertEq(citadelMinter.stakingBps(), 2500);
        assertEq(citadelMinter.lockingBps(), 1000);
        assertEq(citadelMinter.daoBps(), 1500);

        vm.stopPrank();

        // pausing should freeze setCitadelDistributionSplit
        vm.prank(guardian);
        gac.pause();
        vm.prank(address(policyOps));
        vm.expectRevert(bytes("global-paused"));
        citadelMinter.setCitadelDistributionSplit(5000, 2500, 1000, 1500);
    }

    function testSetFundingPoolWeight() public {
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

    function testFundingPoolsMintingDistribution(
        uint256 _x,
        uint256 _y,
        uint256 _fundingWeight
    ) public {
        uint256 MAX_BPS = 10000;
        vm.assume(
            _x <= MAX_BPS &&
                _y <= MAX_BPS &&
                _fundingWeight <= MAX_BPS &&
                _x > 0
        );
        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();

        vm.prank(policyOps);
        citadelMinter.setCitadelDistributionSplit(
            _fundingWeight,
            10000 - _fundingWeight,
            0,
            0
        ); // Funding weight = 50%

        _testSetFundingPoolWeight(address(fundingCvx), _x);
        _testSetFundingPoolWeight(address(fundingWbtc), _y);

        uint256 fundingCvxPoolBalanceBefore = citadel.balanceOf(
            address(fundingCvx)
        );
        uint256 fundingWbtcPoolBalanceBefore = citadel.balanceOf(
            address(fundingWbtc)
        );

        uint256 mintedAmount = mintAndDistribute();

        uint256 fundingCvxPoolBalanceAfter = citadel.balanceOf(
            address(fundingCvx)
        );
        uint256 fundingWbtcPoolBalanceAfter = citadel.balanceOf(
            address(fundingWbtc)
        );

        uint256 fundingCvxReceived = fundingCvxPoolBalanceAfter -
            fundingCvxPoolBalanceBefore;
        uint256 fundingWbtcReceived = fundingWbtcPoolBalanceAfter -
            fundingWbtcPoolBalanceBefore;

        uint256 fundingAmount = (mintedAmount * _fundingWeight) / MAX_BPS;
        emit log_named_uint("Funding Amount", fundingAmount);
        uint256 totalFundingWeight = citadelMinter.totalFundingPoolWeight();
        assertEq(totalFundingWeight, _x + _y);
        // to avoid rounding errors instead of equal
        assertTrue(
            fundingAmount - (fundingCvxReceived + fundingWbtcReceived) < 10
        );

        // fundingPool Received as expected
        assertEq(fundingCvxReceived, (fundingAmount * _x) / totalFundingWeight);
        assertEq(
            fundingWbtcReceived,
            (fundingAmount * _y) / totalFundingWeight
        );

        // remove a pool now
        _testSetFundingPoolWeight(address(fundingWbtc), 0); // 0 weight means pool will be removed

        emit log_named_uint(
            "totalweight",
            citadelMinter.totalFundingPoolWeight()
        );

        totalFundingWeight = citadelMinter.totalFundingPoolWeight();
        assertEq(totalFundingWeight, _x);

        fundingCvxPoolBalanceBefore = citadel.balanceOf(address(fundingCvx));
        fundingWbtcPoolBalanceBefore = citadel.balanceOf(address(fundingWbtc));

        // Again minting

        mintedAmount = mintAndDistribute();

        fundingCvxPoolBalanceAfter = citadel.balanceOf(address(fundingCvx));
        fundingWbtcPoolBalanceAfter = citadel.balanceOf(address(fundingWbtc));

        fundingCvxReceived =
            fundingCvxPoolBalanceAfter -
            fundingCvxPoolBalanceBefore;
        fundingWbtcReceived =
            fundingWbtcPoolBalanceAfter -
            fundingWbtcPoolBalanceBefore;

        fundingAmount = (mintedAmount * _fundingWeight) / MAX_BPS;

        assertEq(fundingWbtcReceived, 0); // fundingWbtc is removed so balance shouldn't change
        assertEq(fundingCvxReceived, fundingAmount); // fundingCvx will receive full funding
    }

    function testMintAndDistribute(uint256 bps_A, uint256 bps_B) public {
        uint256 HALF_MAX_BPS = 5000;
        vm.assume(bps_A <= HALF_MAX_BPS && bps_B <= HALF_MAX_BPS);
        _testMintAndDistribute(
            bps_A,
            HALF_MAX_BPS - bps_A,
            bps_B,
            HALF_MAX_BPS - bps_B
        );
    }

    function testMintAndDistribute_SpecialCases() public {
        _testMintAndDistribute(10000, 0, 0, 0);
        vm.warp(block.timestamp + 1000);
        _testMintAndDistribute(0, 10000, 0, 0);
        vm.warp(block.timestamp + 1000);
        _testMintAndDistribute(0, 0, 10000, 0);
        vm.warp(block.timestamp + 1000);
        _testMintAndDistribute(0, 0, 0, 10000);
        vm.warp(block.timestamp + 1000);
        _testMintAndDistribute(2500, 2500, 2500, 2500);
        vm.warp(block.timestamp + 1000);
        _testMintAndDistribute(5000, 0, 0, 5000);
        vm.warp(block.timestamp + 1000);
        _testMintAndDistribute(1, 1, 1, 9997);
    }

    function _testMintAndDistribute(
        uint256 _bps_A,
        uint256 _bps_B,
        uint256 _bps_C,
        uint256 _bps_D
    ) public {
        TestInfo memory info;
        // Initialize minting timestamp
        vm.startPrank(governance);
        if (schedule.globalStartTimestamp() == 0) {
            schedule.setMintingStart(block.timestamp);
            citadelMinter.initializeLastMintTimestamp();
        }
        vm.stopPrank();

        // Set distribution split
        vm.prank(policyOps);
        citadelMinter.setCitadelDistributionSplit(
            _bps_A, // Funding
            _bps_B, // Staking
            _bps_C, // Locking
            _bps_D // DAO
        );

        // Set funding pool weights (50/50)
        _testSetFundingPoolWeight(address(fundingCvx), 5000);
        _testSetFundingPoolWeight(address(fundingWbtc), 5000);

        info.fundingCvxPoolBalanceBefore = citadel.balanceOf(
            address(fundingCvx)
        );
        info.fundingWbtcPoolBalanceBefore = citadel.balanceOf(
            address(fundingWbtc)
        );
        info.stakingBalanceBefore = citadel.balanceOf(address(xCitadel));
        info.daoBalanceBefore = citadel.balanceOf(address(treasuryVault));

        uint256 mintedAmount = mintAndDistribute();

        info.fundingCvxPoolBalanceAfter = citadel.balanceOf(
            address(fundingCvx)
        );
        info.fundingWbtcPoolBalanceAfter = citadel.balanceOf(
            address(fundingWbtc)
        );
        info.stakingBalanceAfter = citadel.balanceOf(address(xCitadel));
        info.daoBalanceAfter = citadel.balanceOf(address(treasuryVault));

        // Check that Citadel was distributed properly
        assertEq(
            info.fundingCvxPoolBalanceAfter - info.fundingCvxPoolBalanceBefore,
            ((mintedAmount * _bps_A) / (10000)) / 2
        ); // 50% of Funding
        assertEq(
            info.fundingWbtcPoolBalanceAfter -
                info.fundingWbtcPoolBalanceBefore,
            ((mintedAmount * _bps_A) / (10000)) / 2
        ); // 50% of Funding
        assertEq(
            info.stakingBalanceAfter - info.stakingBalanceBefore,
            ((mintedAmount * (_bps_B)) / (10000)) +
                ((mintedAmount * _bps_C) / (10000))
        ); // Staking + Locking
        assertEq(
            info.daoBalanceAfter - info.daoBalanceBefore,
            (mintedAmount * (_bps_D)) / (10000)
        ); // Distributed to Treasury
    }

    function mintAndDistribute() public returns (uint256) {
        vm.warp(block.timestamp + 1000);
        uint256 expectedMint = schedule.getMintable(
            citadelMinter.lastMintTimestamp()
        );
        vm.prank(policyOps);
        citadelMinter.mintAndDistribute();

        return expectedMint;
    }

    function _testSetFundingPoolWeight(address fundingPool, uint256 weight)
        public
    {
        vm.stopPrank();
        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.setFundingPoolWeight(fundingPool, weight);

        vm.startPrank(policyOps);
        if (weight > 10000) {
            vm.expectRevert("exceed max funding pool weight");
            citadelMinter.setFundingPoolWeight(fundingPool, weight);
        } else {
            citadelMinter.setFundingPoolWeight(fundingPool, weight);
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
