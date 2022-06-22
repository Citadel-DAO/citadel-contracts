pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract LockingTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    /*
    Integration test to lock and unlock-
        - user locks amount
        - user can not withdraw before locking period ends
        - user withdraws after locking period ends and recievs locked amount
        - unit tests of lockedBalanceOf function
    */

    function testLockAndUnlock() public {
        address user = address(1);

        uint256 xCitadelLocked = lockAmount();

        vm.startPrank(user);
        assertEq(xCitadelLocked, 10e18);
        assertEq(xCitadelLocker.lockedBalanceOf(user), xCitadelLocked);

        // try to withdraw before the lock duration ends
        vm.expectRevert("no exp locks");
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw

        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)

        uint256 xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw
        uint256 xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        uint256 xCitadelUnlocked = xCitadelUserBalanceAfter -
            xCitadelUserBalanceBefore;

        // user gets unlocked amount
        assertEq(xCitadelUnlocked, xCitadelLocked);
        // locked balance should be zero
        assertEq(xCitadelLocker.lockedBalanceOf(user), 0);

        vm.stopPrank();
    }

    /*
    Integration test to test getReward -
        - user locks amount, minting happens
        - after some time from locking user can receive by calling getReward
        - getCumulativeClaimedRewards returns expected
    */
    function testGetReward() public {
        address user = address(1);

        lockAmount();

        mintAndDistribute();

        treasuryReward();

        vm.startPrank(user);

        uint256 wbtcCumulatedClaimedBefore = xCitadelLocker
            .getCumulativeClaimedRewards(user, wbtc_address);
        uint256 xCitadelCumulatedClaimedBefore = xCitadelLocker
            .getCumulativeClaimedRewards(user, address(xCitadel));

        uint256 xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        uint256 wbtcUserBalanceBefore = wbtc.balanceOf(user);
        vm.warp(block.timestamp + 1); // move sometime forward to receive some rewards

        xCitadelLocker.getReward(user); // user collects rewards

        uint256 xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        uint256 wbtcUserBalanceAfter = wbtc.balanceOf(user);

        // check if cumulativeClaimed is updated correctly
        assertEq(
            xCitadelLocker.getCumulativeClaimedRewards(user, wbtc_address),
            wbtcCumulatedClaimedBefore +
                wbtcUserBalanceAfter -
                wbtcUserBalanceBefore
        );
        assertEq(
            xCitadelLocker.getCumulativeClaimedRewards(user, address(xCitadel)),
            xCitadelCumulatedClaimedBefore +
                xCitadelUserBalanceAfter -
                xCitadelUserBalanceBefore
        );

        wbtcCumulatedClaimedBefore = xCitadelLocker.getCumulativeClaimedRewards(
                user,
                wbtc_address
            );
        xCitadelCumulatedClaimedBefore = xCitadelLocker
            .getCumulativeClaimedRewards(user, address(xCitadel));

        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        wbtcUserBalanceBefore = wbtc.balanceOf(user);
        vm.warp(block.timestamp + 2); // move sometime forward to receive more rewards

        xCitadelLocker.getReward(user); // user collects rewards

        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        wbtcUserBalanceAfter = wbtc.balanceOf(user);

        // check if cumulativeClaimed is updated correctly
        assertEq(
            xCitadelLocker.getCumulativeClaimedRewards(user, wbtc_address),
            wbtcCumulatedClaimedBefore +
                wbtcUserBalanceAfter -
                wbtcUserBalanceBefore
        );
        assertEq(
            xCitadelLocker.getCumulativeClaimedRewards(user, address(xCitadel)),
            xCitadelCumulatedClaimedBefore +
                xCitadelUserBalanceAfter -
                xCitadelUserBalanceBefore
        );
    }

    /*
    Integration test to test relock-
        - user locks amount
        - After locking period user relocks
        - user can not unlock the relocked amount without 2nd locking period
        - after 2nd locking period ends user can unlock or relock
    */
    function testRelocking() public {
        address user = address(1);

        uint256 xCitadelLocked = lockAmount();
        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)

        vm.startPrank(user);
        uint256 xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadelLocker.processExpiredLocks(true); // relock
        uint256 xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        uint256 xCitadelUnlocked = xCitadelUserBalanceAfter -
            xCitadelUserBalanceBefore;

        assertEq(xCitadelUnlocked, 0); // user relocked xCitadel

        // as user has relocked, user can not withdraw
        vm.expectRevert("no exp locks");
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw

        vm.warp(block.timestamp + 147 days); // move forward so that lock duration ends

        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw
        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        xCitadelUnlocked = xCitadelUserBalanceAfter - xCitadelUserBalanceBefore;

        assertEq(xCitadelUnlocked, xCitadelLocked);
        vm.stopPrank();
    }

    /*
    Integration test to test kick rewards
        - user1 locks amount
        - kickExpiredLocks should revert if locked period is not over
        - kickExpiredLocks should reward expected amount
        - kickExpiredLocks should unlock and user1 received expected
    */
    function testKickRewards() public {
        address user = address(1);

        uint256 xCitadelLocked = lockAmount();

        mintAndDistribute();

        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)

        address user2 = address(2);
        vm.startPrank(user2);
        // should revert cause unlocktime > currentTime - _checkdelay
        vm.expectRevert("no exp locks");
        xCitadelLocker.kickExpiredLocks(user); // kick expired locks

        // move forward atleast 4 days cause kickRewardEpochDelay = 4
        vm.warp(block.timestamp + 6 days);
        uint256 denominator = 10000;
        uint256 kickRewardPerEpoch = 100;
        uint256 epochsover = 2;
        uint256 rRate = kickRewardPerEpoch * (epochsover + 1);

        uint256 reward = (uint256(10e18) * (rRate)) / (denominator);

        uint256 xCitadelUser2BalanceBefore = xCitadel.balanceOf(user2);
        uint256 xCitadelUserBalanceBefore = xCitadel.balanceOf(user);

        xCitadelLocker.kickExpiredLocks(user); // kick expired locks
        uint256 xCitadelUser2BalanceAfter = xCitadel.balanceOf(user2);
        uint256 xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        uint256 user2ReceivedAward = xCitadelUser2BalanceAfter -
            xCitadelUser2BalanceBefore;
        uint256 unlockedAmount = xCitadelUserBalanceAfter -
            xCitadelUserBalanceBefore;

        assertEq(user2ReceivedAward + unlockedAmount, xCitadelLocked);
        assertEq(user2ReceivedAward, reward);
        emit log_named_uint("Reward Amount", user2ReceivedAward);
        emit log_named_uint("Unlocked Amount", unlockedAmount);

        vm.stopPrank();
    }

    /*
    Unit tests for notifyRewardAmount function
        - checks only approved reward distributors can reward
        - checks cumulativeDistributed returns as expected after each notifyreward
    */
    function testNotifyReward() public {
        // to add wbtc rewards
        treasuryReward();

        assertEq(xCitadelLocker.cumulativeDistributed(wbtc_address), 10e8);

        uint256 balanceBefore = wbtc.balanceOf(address(2));
        vm.prank(address(2));
        vm.expectRevert();
        xCitadelLocker.notifyRewardAmount(wbtc_address, 10e8); // address(2) try to give rewards

        uint256 balanceAfter = wbtc.balanceOf(address(2));
        assertEq(balanceBefore, balanceAfter);

        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.approveRewardDistributor(wbtc_address, address(2), true);

        vm.startPrank(governance);
        erc20utils.forceMintTo(address(2), wbtc_address, 100e8); // so that address(2) can reward lockers
        xCitadelLocker.approveRewardDistributor(wbtc_address, address(2), true);
        vm.stopPrank();

        vm.startPrank(address(2));
        wbtc.approve(address(xCitadelLocker), 100e8);
        balanceBefore = wbtc.balanceOf(address(2));

        xCitadelLocker.notifyRewardAmount(wbtc_address, 10e8); // give some rewards

        balanceAfter = wbtc.balanceOf(address(2));

        assertEq(balanceBefore - balanceAfter, 10e8);

        // cumulativeDistributed should be incremented to 20e8
        assertEq(xCitadelLocker.cumulativeDistributed(wbtc_address), 20e8);

        vm.stopPrank();
    }

    /*
    Unit tests for recoverERC20
        - check recoverERC20 can not withdraw staking token
        - check recoverERC20 can not withdraw reward token
        - check recoverERC20 sends assets to treasuryVault
    */
    function testRecoverERC20() public {
        vm.startPrank(rando);
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.recoverERC20(address(citadel), 10e18);
        vm.stopPrank();

        vm.startPrank(governance);
        citadel.mint(address(xCitadelLocker), 10e18);
        xCitadelLocker.addReward(wbtc_address, treasuryVault, false); // add reward so that lockers can receive treasury share

        vm.expectRevert("Cannot withdraw staking token");
        xCitadelLocker.recoverERC20(address(xCitadel), 10e18);

        vm.expectRevert("Cannot withdraw reward token");
        xCitadelLocker.recoverERC20(wbtc_address, 10e18);

        uint256 lockerCitadelBefore = citadel.balanceOf(
            address(xCitadelLocker)
        );
        uint256 treasuryCitadelBefore = citadel.balanceOf(treasuryVault);
        xCitadelLocker.recoverERC20(address(citadel), 10e18);
        uint256 lockerCitadelAfter = citadel.balanceOf(address(xCitadelLocker));
        uint256 treasuryCitadelAfter = citadel.balanceOf(treasuryVault);

        assertEq(lockerCitadelBefore - lockerCitadelAfter, 10e18);
        assertEq(treasuryCitadelAfter - treasuryCitadelBefore, 10e18); // Transferred to treasuryVault

        vm.stopPrank();
    }

    /*
    Unit tests for shutDown-
        - shutdown doesn't allow locking
        - lock function reverts as expected
    */
    function testShutDown() public {
        vm.startPrank(rando);
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.shutdown();
        vm.stopPrank();

        vm.prank(governance);
        xCitadelLocker.shutdown();

        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(rando, 100e18); // so that user can stake and get xCitadel

        vm.startPrank(rando);
        citadel.approve(address(xCitadel), 10e18); // approve staking amount
        xCitadel.deposit(10e18); // stake and get xCitadel

        uint256 xCitadelUserBalanceBefore = xCitadel.balanceOf(rando);
        xCitadel.approve(address(xCitadelLocker), xCitadelUserBalanceBefore);

        vm.expectRevert("shutdown");
        xCitadelLocker.lock(rando, xCitadelUserBalanceBefore, 0); // lock xCitadel
        uint256 xCitadelUserBalanceAfter = xCitadel.balanceOf(rando);

        assertEq(xCitadelUserBalanceAfter, xCitadelUserBalanceBefore);
    }

    /*
    Unit tests for view functions- 
        - getRewardTokens
        - lastTimeRewardApplicable
        - getRewardForDuration
    */
    function testViewFunctions() public {
        address user = address(1);
        lockAmount();

        address[] memory tokens = xCitadelLocker.getRewardTokens();
        assertEq(tokens.length, 1); // only citadel rewards
        assertEq(tokens[0], address(xCitadel));

        uint256 timestamp = block.timestamp; // the moment rewards are distributed
        treasuryReward();

        tokens = xCitadelLocker.getRewardTokens();
        assertEq(tokens.length, 2); // citadel and wbtc rewards
        assertEq(tokens[1], address(wbtc));

        uint256 lastUpdatedRewardTime = xCitadelLocker.lastTimeRewardApplicable(
            address(wbtc)
        );

        assertEq(lastUpdatedRewardTime, block.timestamp);

        vm.warp(block.timestamp + 2 days);

        lastUpdatedRewardTime = xCitadelLocker.lastTimeRewardApplicable(
            address(wbtc)
        );

        assertEq(lastUpdatedRewardTime, timestamp + 1 days); // block.timestamp + rewardsDuration

        uint256 reward = xCitadelLocker.getRewardForDuration(address(wbtc));

        uint256 rewardsDuration = xCitadelLocker.rewardsDuration();
        assertEq(reward, (10e8 / rewardsDuration) * rewardsDuration); // rewardRate*rewardsDuration

        emit log_named_uint("boosted Supply", xCitadelLocker.boostedSupply());
    }

    // helper function to lock amount in locker
    function lockAmount() public returns (uint256) {
        address user = address(1);

        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 100e18); // so that user can stake and get xCitadel

        vm.startPrank(user);
        citadel.approve(address(xCitadel), 10e18); // approve staking amount
        xCitadel.deposit(10e18); // stake and get xCitadel

        uint256 xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadel.approve(address(xCitadelLocker), xCitadelUserBalanceBefore);

        xCitadelLocker.lock(user, xCitadelUserBalanceBefore, 0); // lock xCitadel
        uint256 xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        assertEq(xCitadelUserBalanceBefore - xCitadelUserBalanceAfter, 10e18);

        vm.stopPrank();

        return xCitadelUserBalanceBefore - xCitadelUserBalanceAfter;
    }

    // helper function for minting
    function mintAndDistribute() public {
        // mint and distribute , lockers will receive xCTDL as rewards
        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();
        vm.warp(block.timestamp + 1000);
        vm.startPrank(policyOps);
        citadelMinter.setFundingPoolWeight(address(fundingWbtc), 10000);
        citadelMinter.setCitadelDistributionSplit(5000, 2000, 2000, 1000);
        citadelMinter.mintAndDistribute();
        vm.stopPrank();
    }

    /*
    helper function to distribute treasury reward 
    */
    function treasuryReward() public {
        vm.startPrank(governance);
        erc20utils.forceMintTo(treasuryVault, wbtc_address, 100e8); // so that treasury can reward lockers
        xCitadelLocker.addReward(wbtc_address, treasuryVault, false); // add reward so that lockers can receive treasury share
        vm.stopPrank();
        // treasury funding, lockers will receive wBTC as rewards
        vm.startPrank(treasuryVault);
        wbtc.approve(address(xCitadelLocker), 100e8);
        xCitadelLocker.notifyRewardAmount(wbtc_address, 10e8); // share of treasury yield
        assertEq(xCitadelLocker.cumulativeDistributed(wbtc_address), 10e8);

        vm.stopPrank();
    }
}
