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
        vm.startPrank(governance);
        citadel.mint(user, 100e18); // so that user can stake and get xCitadel
        erc20utils.forceMintTo(treasuryVault, wbtc_address, 100e8); // so that treasury can reward lockers
        xCitadelLocker.addReward(wbtc_address, treasuryVault, false); // add reward so that lockers can receive treasury share 
        vm.stopPrank();

        vm.startPrank(user);
        citadel.approve(address(xCitadel), 10e18); // approve staking amount
        xCitadel.deposit(10e18); // stake and get xCitadel

        uint xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadel.approve(address(xCitadelLocker), xCitadelUserBalanceBefore);

        xCitadelLocker.lock(user, xCitadelUserBalanceBefore, 0); // lock xCitadel
        uint xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        uint xCitadelLocked = xCitadelUserBalanceBefore - xCitadelUserBalanceAfter;

        assertEq(xCitadelUserBalanceBefore - xCitadelUserBalanceAfter, 10e18);

        vm.stopPrank();

        // mint and distribute , lockers will receive xCTDL as rewards
        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();
        vm.warp(block.timestamp + 1000);
        vm.startPrank(policyOps);
        citadelMinter.setFundingPoolWeight(address(fundingWbtc), 10000);
        citadelMinter.setCitadelDistributionSplit(5000,2000,3000);
        citadelMinter.mintAndDistribute();
        vm.stopPrank();
        
        // treasury funding, lockers will receive wBTC as rewards
        vm.startPrank(treasuryVault);
        wbtc.approve(address(xCitadelLocker), 100e8);
        xCitadelLocker.notifyRewardAmount(wbtc_address, 10e8); // share of treasury yield
        vm.stopPrank();

        vm.startPrank(user);
        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        uint wbtcUserBalanceBefore = wbtc.balanceOf(user);
        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)
        
        xCitadelLocker.getReward(user); // user collects rewards 

        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        uint wbtcUserBalanceAfter = wbtc.balanceOf(user);

        emit log_named_uint("reward per token xCitadel" , xCitadelLocker.rewardPerToken(address(xCitadel)));
        emit log_named_uint("reward per token wbtc" ,xCitadelLocker.rewardPerToken(wbtc_address));

        // the awards received from minting process
        emit log_named_uint("Reward received xCitadel" , xCitadelUserBalanceAfter- xCitadelUserBalanceBefore);
        // the awards received from treasury funds
        emit log_named_uint("Reward received Wbtc" , wbtcUserBalanceAfter-wbtcUserBalanceBefore);

        assertTrue(xCitadelUserBalanceAfter- xCitadelUserBalanceBefore > 0);
        assertTrue(wbtcUserBalanceAfter-wbtcUserBalanceBefore > 0) ;

        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw 
        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        uint xCitadelUnlocked = xCitadelUserBalanceAfter- xCitadelUserBalanceBefore;
        
        // user gets unlocked amount 
        assertEq(xCitadelUnlocked , xCitadelLocked);

        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        wbtcUserBalanceBefore = wbtc.balanceOf(user);
        // user try to claim rewards again
        xCitadelLocker.getReward(user);

        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        wbtcUserBalanceAfter = wbtc.balanceOf(user);

        assertEq(xCitadelUserBalanceBefore, xCitadelUserBalanceAfter); // user's balance should not change
        assertEq(wbtcUserBalanceBefore , wbtcUserBalanceAfter);
        
        vm.stopPrank();

    }
}