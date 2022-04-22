pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract LockingTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();

    }

    function testUnlockAndReward() public{
        address user = address(1);

        uint xCitadelLocked = lockAmount();
       
        mintAndDistribute();

        treasuryReward();
        
        vm.startPrank(user);

        // try to withdraw before the lock duration ends
        vm.expectRevert("no exp locks");
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw 

        uint xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        uint wbtcUserBalanceBefore = wbtc.balanceOf(user);
        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)
        
        xCitadelLocker.getReward(user); // user collects rewards 

        uint xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        
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

    function testRelocking() public{
        address user = address(1);

        uint xCitadelLocked = lockAmount();
        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)
        
        vm.startPrank(user);
        uint xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadelLocker.processExpiredLocks(true); // relock 
        uint xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        uint xCitadelUnlocked = xCitadelUserBalanceAfter- xCitadelUserBalanceBefore;
        
        assertEq(xCitadelUnlocked, 0); // user relocked xCitadel

        // as user has relocked, user can not withdraw 
        vm.expectRevert("no exp locks");
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw 

        vm.warp(block.timestamp + 147 days); // move forward so that lock duration ends

        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw 
        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        xCitadelUnlocked = xCitadelUserBalanceAfter- xCitadelUserBalanceBefore;
        
        assertEq(xCitadelUnlocked, xCitadelLocked);
        vm.stopPrank();
    }

    function testKickRewards() public{
        address user = address(1);

        uint xCitadelLocked = lockAmount();

        mintAndDistribute();

        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)
        
        address user2 = address(2);
        vm.startPrank(user2);
        // should revert cause unlocktime > currentTime - _checkdelay
        vm.expectRevert("no exp locks");
        xCitadelLocker.kickExpiredLocks(user); // kick expired locks 

        // move forward atleast 4 days cause kickRewardEpochDelay = 4 
        vm.warp(block.timestamp + 6 days);

        uint xCitadelUser2BalanceBefore = xCitadel.balanceOf(user2);
        uint xCitadelUserBalanceBefore = xCitadel.balanceOf(user);

        xCitadelLocker.kickExpiredLocks(user); // kick expired locks 
        uint xCitadelUser2BalanceAfter = xCitadel.balanceOf(user2);
        uint xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        
        uint user2ReceivedAward = xCitadelUser2BalanceAfter- xCitadelUser2BalanceBefore;
        uint unlockedAmount = xCitadelUserBalanceAfter - xCitadelUserBalanceBefore ; 

        assertEq(user2ReceivedAward + unlockedAmount , xCitadelLocked);
        emit log_named_uint("Reward Amount" , user2ReceivedAward);
        emit log_named_uint("Unlocked Amount", unlockedAmount);

        vm.stopPrank();


    }

    function testRecoverERC20() public {

        vm.expectRevert("Ownable: caller is not the owner");
        xCitadelLocker.recoverERC20(address(citadel), 10e18);

        vm.startPrank(governance);
        citadel.mint(address(xCitadelLocker), 10e18); // 
        xCitadelLocker.addReward(wbtc_address, treasuryVault, false); // add reward so that lockers can receive treasury share 

        vm.expectRevert("Cannot withdraw staking token");
        xCitadelLocker.recoverERC20(address(xCitadel), 10e18);

        vm.expectRevert("Cannot withdraw reward token");
        xCitadelLocker.recoverERC20(wbtc_address, 10e18);

        uint lockerCitadelBefore = citadel.balanceOf(address(xCitadelLocker));
        uint governanceCitadelBefore = citadel.balanceOf(governance);
        xCitadelLocker.recoverERC20(address(citadel), 10e18);
        uint lockerCitadelAfter = citadel.balanceOf(address(xCitadelLocker));
        uint governanceCitadelAfter = citadel.balanceOf(governance);

        assertEq(lockerCitadelBefore - lockerCitadelAfter, 10e18);
        assertEq(governanceCitadelAfter - governanceCitadelBefore, 10e18); //owner received 

        vm.stopPrank();

    }

    function testShutDown() public {
        address user = address(1);
        vm.expectRevert("Ownable: caller is not the owner");
        xCitadelLocker.shutdown();

        vm.prank(governance);
        xCitadelLocker.shutdown();

        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 100e18); // so that user can stake and get xCitadel

        vm.startPrank(user);
        citadel.approve(address(xCitadel), 10e18); // approve staking amount
        xCitadel.deposit(10e18); // stake and get xCitadel

        uint xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadel.approve(address(xCitadelLocker), xCitadelUserBalanceBefore);
        
        vm.expectRevert("shutdown");
        xCitadelLocker.lock(user, xCitadelUserBalanceBefore, 0); // lock xCitadel
        uint xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        assertEq(xCitadelUserBalanceAfter , xCitadelUserBalanceBefore);

    }

    function lockAmount() public returns(uint){
        address user = address(1);

        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 100e18); // so that user can stake and get xCitadel

        vm.startPrank(user);
        citadel.approve(address(xCitadel), 10e18); // approve staking amount
        xCitadel.deposit(10e18); // stake and get xCitadel

        uint xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadel.approve(address(xCitadelLocker), xCitadelUserBalanceBefore);

        xCitadelLocker.lock(user, xCitadelUserBalanceBefore, 0); // lock xCitadel
        uint xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        assertEq(xCitadelUserBalanceBefore - xCitadelUserBalanceAfter, 10e18);

        vm.stopPrank();

        return xCitadelUserBalanceBefore - xCitadelUserBalanceAfter;

    }

    function mintAndDistribute() public{

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
        
    }

    function treasuryReward() public{

        vm.startPrank(governance);
        erc20utils.forceMintTo(treasuryVault, wbtc_address, 100e8); // so that treasury can reward lockers
        xCitadelLocker.addReward(wbtc_address, treasuryVault, false); // add reward so that lockers can receive treasury share 
        vm.stopPrank();
        // treasury funding, lockers will receive wBTC as rewards
        vm.startPrank(treasuryVault);
        wbtc.approve(address(xCitadelLocker), 100e8);
        xCitadelLocker.notifyRewardAmount(wbtc_address, 10e8); // share of treasury yield
        vm.stopPrank();

    }
}