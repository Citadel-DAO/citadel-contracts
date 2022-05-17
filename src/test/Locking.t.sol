pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract LockingTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testUnlockAndReward() public {
        address user = address(1);

        uint256 xCitadelLocked = lockAmount();

        assertEq(xCitadelLocker.lockedBalanceOf(user), xCitadelLocked);

        mintAndDistribute();

        treasuryReward();

        vm.startPrank(user);

        // try to withdraw before the lock duration ends
        vm.expectRevert("no exp locks");
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw

        uint256 xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        uint256 wbtcUserBalanceBefore = wbtc.balanceOf(user);
        vm.warp(block.timestamp + 148 days); // lock period = 147 days + 1 day(rewards_duration cause 1st time lock)

        xCitadelLocker.getReward(user); // user collects rewards

        uint256 xCitadelUserBalanceAfter = xCitadel.balanceOf(user);

        uint256 wbtcUserBalanceAfter = wbtc.balanceOf(user);

        emit log_named_uint(
            "reward per token xCitadel",
            xCitadelLocker.rewardPerToken(address(xCitadel))
        );
        emit log_named_uint(
            "reward per token wbtc",
            xCitadelLocker.rewardPerToken(wbtc_address)
        );

        // the awards received from minting process
        emit log_named_uint(
            "Reward received xCitadel",
            xCitadelUserBalanceAfter - xCitadelUserBalanceBefore
        );
        // the awards received from treasury funds
        emit log_named_uint(
            "Reward received Wbtc",
            wbtcUserBalanceAfter - wbtcUserBalanceBefore
        );

        assertTrue(xCitadelUserBalanceAfter - xCitadelUserBalanceBefore > 0);
        assertTrue(wbtcUserBalanceAfter - wbtcUserBalanceBefore > 0);

        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        xCitadelLocker.withdrawExpiredLocksTo(user); // withdraw
        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        uint256 xCitadelUnlocked = xCitadelUserBalanceAfter -
            xCitadelUserBalanceBefore;

        // user gets unlocked amount
        assertEq(xCitadelUnlocked, xCitadelLocked);
        assertEq(xCitadelLocker.lockedBalanceOf(user), 0);
        xCitadelUserBalanceBefore = xCitadel.balanceOf(user);
        wbtcUserBalanceBefore = wbtc.balanceOf(user);
        // user try to claim rewards again
        xCitadelLocker.getReward(user);

        xCitadelUserBalanceAfter = xCitadel.balanceOf(user);
        wbtcUserBalanceAfter = wbtc.balanceOf(user);

        assertEq(xCitadelUserBalanceBefore, xCitadelUserBalanceAfter); // user's balance should not change
        assertEq(wbtcUserBalanceBefore, wbtcUserBalanceAfter);

        vm.stopPrank();
    }

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

    function testNotifyReward() public {
        treasuryReward();

        uint256 balanceBefore = wbtc.balanceOf(address(2));
        vm.prank(address(2));
        vm.expectRevert();
        xCitadelLocker.notifyRewardAmount(wbtc_address, 10e8); // share of treasury yield
        uint256 balanceAfter = wbtc.balanceOf(address(2));

        assertEq(balanceBefore, balanceAfter);

        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.approveRewardDistributor(wbtc_address, address(2), true);

        vm.startPrank(governance);
        xCitadelLocker.approveRewardDistributor(wbtc_address, address(2), true);
        erc20utils.forceMintTo(address(2), wbtc_address, 100e8); // so that treasury can reward lockers
        vm.stopPrank();

        vm.startPrank(address(2));
        wbtc.approve(address(xCitadelLocker), 100e8);
        balanceBefore = wbtc.balanceOf(address(2));

        xCitadelLocker.notifyRewardAmount(wbtc_address, 10e8); // share of treasury yield

        balanceAfter = wbtc.balanceOf(address(2));

        assertEq(balanceBefore - balanceAfter, 10e8);
        vm.stopPrank();
    }

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

    function testLockedBalances() public {
        // address user = address(1);
        // uint256 xCitadelLocked = lockAmount();
        // (uint locked, uint unlockable, xCitadelLocker.lockedBalances(user);
    }

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

        uint256 rewardWeight = xCitadelLocker.rewardWeightOf(user);

        emit log_named_uint("rewardWeight", rewardWeight);

        emit log_named_uint("boosted Supply", xCitadelLocker.boostedSupply());
    }

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

    function treasuryReward() public {
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
