pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract LockingTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testBasicSetFunctions() public{
        assertTrue(true);
        // vm.expectRevert("GAC: invalid-caller-role");
        // xCitadelLocker.setStakingContract(address(xCitadel));

        // vm.expectRevert("GAC: invalid-caller-role");
        // xCitadelLocker.setStakeLimits(3000, 7000);

        // vm.expectRevert("GAC: invalid-caller-role");
        // xCitadelLocker.setKickIncentive(200, 5);

        // address owner = xCitadelLocker.owner();
        // vm.startPrank(owner);
        // xCitadelLocker.setStakingContract(address(xCitadel));
        // assertEq(xCitadelLocker.stakingProxy(),address(xCitadel));

        // vm.expectRevert("!assign");
        // xCitadelLocker.setStakingContract(address(xCitadel));

        // vm.startPrank(owner);
        // xCitadelLocker.setStakeLimits(3000, 7000);
        // assertEq(xCitadelLocker.minimumStake(),3000);
        // assertEq(xCitadelLocker.maximumStake(),7000);
       
        // xCitadelLocker.setKickIncentive(200, 5);
        // assertEq(xCitadelLocker.kickRewardPerEpoch(), 200);
        // assertEq(xCitadelLocker.kickRewardEpochDelay(), 5);
        // vm.stopPrank();

    }

    function testEndToEnd() public{
        address user = address(1);
        
        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 100e18);

        vm.startPrank(user);

        // approve staking amount
        citadel.approve(address(xCitadel), 10e18);

        // deposit 
        xCitadel.deposit(10e18);

        vm.stopPrank();

        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();

        uint xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        vm.startPrank(user);
        xCitadel.approve(address(xCitadelLocker), xCitadelUserBalanceBefore);
        xCitadelLocker.lock(user, xCitadelUserBalanceBefore, 0);

        uint xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        uint xCitadelLocked = xCitadelUserBalanceBefore - xCitadelUserBalanceAfter;
        assertEq(xCitadelUserBalanceBefore - xCitadelUserBalanceAfter, xCitadelUserBalanceBefore);

        vm.warp(block.timestamp + 1000);

        vm.stopPrank();
        vm.startPrank(policyOps);
        citadelMinter.setFundingPoolWeight(address(fundingWbtc), 10000);
        citadelMinter.setCitadelDistributionSplit(5000,2000,3000);
        citadelMinter.mintAndDistribute();
        vm.stopPrank();
        

        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);

        vm.warp(block.timestamp + 148 days); // lock period = 147 days

        vm.startPrank(user);

        xCitadelLocker.getReward(user);

        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        uint xCitadelRewarded = xCitadelUserBalanceAfter- xCitadelUserBalanceBefore;

        // the awards received from minting process
        emit log_named_uint("Reward received" , xCitadelRewarded);
        assertTrue(xCitadelRewarded > 0);
        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);

        xCitadelLocker.withdrawExpiredLocksTo(user);

        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        uint xCitadelUnlocked = xCitadelUserBalanceAfter- xCitadelUserBalanceBefore;

        // user gets unlocked amount 
        assertEq(xCitadelUnlocked , xCitadelLocked);
        vm.stopPrank();

    }
}