pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @notice Staking user flow tests
contract StakingTest is BaseFixture {
    using FixedPointMathLib for uint256;

    // To avoid "Stack to deep" error
    struct TestInfo {
        uint256 userCitadelBefore;
        uint256 xCitadelBalanceBefore;
        uint256 userXCitadelBefore;
        uint256 xCitadelTotalSupplyBefore;
        uint256 userCitadelAfter;
        uint256 xCitadelBalanceAfter;
        uint256 userXCitadelAfter;
        uint256 xCitadelTotalSupplyAfter;
        uint256 strategyCitadelBefore;
        uint256 vaultCitadelBefore;
        uint256 strategyCitadelAfter;
        uint256 vaultCitadelAfter;
        uint256 vestingCitadelBefore;
        uint256 vestingCitadelAfter;
        uint256 available;
    }

    function setUp() public override {
        BaseFixture.setUp();
    }

    /* 
    Integration test to check that
        - A user stakes amount
        - mintAndDistribute function distributes citadel to staking users
        - withdraw sends users citadel in vesting contract
        - vesting period starts
        - user's claimable balance updates with time
        - After vesting period user received more citadel because of minting happened
    */
    function testUserStakingFlow() public {
        address user = address(1);

        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 100e18);
        assertEq(citadel.balanceOf(user), 100e18);

        uint256 userCitadelBefore = citadel.balanceOf(user);
        uint256 xCitadelBalanceBefore = xCitadel.balance();
        uint256 userXCitadelBefore = xCitadel.balanceOf(user);
        uint256 xCitadelTotalSupplyBefore = xCitadel.totalSupply();

        vm.startPrank(user);

        // approve staking amount
        citadel.approve(address(xCitadel), 10e18);

        // deposit
        xCitadel.deposit(10e18);

        vm.stopPrank();

        uint256 userCitadelAfter = citadel.balanceOf(user);
        uint256 xCitadelBalanceAfter = xCitadel.balance();
        uint256 userXCitadelAfter = xCitadel.balanceOf(user);
        uint256 xCitadelTotalSupplyAfter = xCitadel.totalSupply();

        // check if user has successfully deposited
        assertEq(userCitadelBefore - userCitadelAfter, 10e18);
        assertEq(userXCitadelAfter - userXCitadelBefore, 10e18); // user should have got same amount as totalSupply was zero
        assertEq(xCitadelBalanceAfter - xCitadelBalanceBefore, 10e18); // xCitadel should have some citadel
        // total supply should have incremented
        assertEq(xCitadelTotalSupplyAfter - xCitadelTotalSupplyBefore, 10e18);

        mintAndDistribute();

        uint256 vestingCitadelBefore = citadel.balanceOf(
            address(xCitadelVester)
        );

        // user withdraws all amount
        vm.startPrank(user);
        xCitadel.withdrawAll();

        // the amount should go in vesting
        uint256 vestingCitadelAfter = citadel.balanceOf(
            address(xCitadelVester)
        );

        // as pricePerShare is increased, vesting should receive more amount than deposited.
        uint256 expectedClaimableBalance = (xCitadel.balance() *
            userXCitadelAfter) / xCitadel.totalSupply();

        assertEq(
            vestingCitadelAfter - vestingCitadelBefore,
            expectedClaimableBalance
        );

        // moving half duration
        vm.warp(
            block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION() / 2
        );

        // at half duration. user should be able claim half amount
        assertEq(
            xCitadelVester.claimableBalance(user),
            expectedClaimableBalance / 2
        );

        // move forward so that the vesting period ends
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION());

        // as the vesting period is ended. user should be able claim full amount
        assertEq(
            xCitadelVester.claimableBalance(user),
            expectedClaimableBalance
        );

        userCitadelBefore = citadel.balanceOf(user);

        // expectedClaimableBalance is more than deposited amount
        assertTrue(expectedClaimableBalance > 10e18);
        xCitadelVester.claim(user, expectedClaimableBalance);
        userCitadelAfter = citadel.balanceOf(user);

        // user should have got expected amount back
        assertEq(
            userCitadelAfter - userCitadelBefore,
            expectedClaimableBalance
        );
        vm.stopPrank();
    }

    /*
    Integration test for multiple users staking at the same time
        - 3 users perform different actions staking/deposit
        - minting happens everyone gets expected
        - users again perform different actions partial withdrawl/ full withdraw / more staking
        - again minting happens everyone gets as expected
    */

    function testMultipleUserFlow() public {
        address user1 = address(1);
        address user2 = address(2);
        address user3 = address(3);

        // giving user some citadel to stake
        vm.startPrank(governance);
        citadel.mint(user1, 100e18);
        citadel.mint(user2, 100e18);
        citadel.mint(user3, 100e18);
        vm.stopPrank();

        // user1 deposits some amount
        vm.startPrank(user1);
        citadel.approve(address(xCitadel), 10e18); // approve staking amount
        xCitadel.deposit(10e18); // deposit
        vm.stopPrank();

        // user2 deposits some amount
        vm.startPrank(user2);
        citadel.approve(address(xCitadel), 15e18); // approve staking amount
        xCitadel.deposit(15e18); // deposit
        vm.stopPrank();

        mintAndDistribute(); // minting 1st

        uint256 user1AmountMinting1 = (xCitadel.balance() *
            xCitadel.balanceOf(user1)) / xCitadel.totalSupply();
        uint256 user2AmountMinting1 = (xCitadel.balance() *
            xCitadel.balanceOf(user2)) / xCitadel.totalSupply();
        uint256 user3AmountMinting1 = (
            (xCitadel.balance() * xCitadel.balanceOf(user3))
        ) / xCitadel.totalSupply();

        // user1 should have more than deposited because of minting
        assertTrue(user1AmountMinting1 > 10e18);
        // user2 should have more than deposited because of minting
        assertTrue(user2AmountMinting1 > 15e18);
        // as user3 has not deposited anything yet
        assertEq(user3AmountMinting1, 0);

        vm.prank(user1);
        xCitadel.withdrawAll();

        // user3 depositing note that user3 deposits same amount as user2
        vm.startPrank(user3);
        citadel.approve(address(xCitadel), 15e18); // approve staking amount
        xCitadel.deposit(15e18); // deposit
        vm.stopPrank();

        // vm.prank(user3);
        // xCitadel.withdraw(10e18); // withdraw some amount only

        // move forward so that the vesting period ends
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION());

        // as the vesting period is ended. user1 should be able claim full amount
        assertEq(xCitadelVester.claimableBalance(user1), user1AmountMinting1);

        // as user2 has not done any withdrawls
        assertEq(xCitadelVester.claimableBalance(user2), 0);
        // as user3 has not done any withdrawls
        assertEq(xCitadelVester.claimableBalance(user3), 0);

        // minting again 2nd
        vm.warp(block.timestamp + 2000);

        vm.prank(policyOps);
        citadelMinter.mintAndDistribute();

        uint256 user1AmountMinting2 = (xCitadel.balance() *
            xCitadel.balanceOf(user1)) / xCitadel.totalSupply();
        uint256 user2AmountMinting2 = (xCitadel.balance() *
            xCitadel.balanceOf(user2)) / xCitadel.totalSupply();
        uint256 user3AmountMinting2 = (
            (xCitadel.balance() * xCitadel.balanceOf(user3))
        ) / xCitadel.totalSupply();

        // user1 has withdrawn all before 2nd minting so no amount after minting
        assertTrue(user1AmountMinting2 == 0);
        // user2 should have more than user2AmountMinting1 deposited because of 2 minting cycles
        assertTrue(user2AmountMinting2 > user2AmountMinting1);
        // for user3
        assertTrue(user3AmountMinting2 > 15e18);
        // as user2 deposited before 2 minting cycles and user3 deposited just before 1 minting cycle
        // user2 will get more amount than user3
        assertTrue(user2AmountMinting2 > user3AmountMinting2);

        // user2 withdraws some amount
        vm.prank(user2);
        xCitadel.withdraw(5e18);

        uint256 expectedClaimableAmount2 = (xCitadel.balance() * 5e18) /
            xCitadel.totalSupply();

        // move forward so that the vesting period ends
        vm.warp(block.timestamp + xCitadelVester.INITIAL_VESTING_DURATION());

        // as the vesting period is ended.
        // user1 still have claimable balance as user1 has not claimed it yet
        assertEq(xCitadelVester.claimableBalance(user1), user1AmountMinting1);
        // as user2 has withdrawn some amount
        assertEq(
            xCitadelVester.claimableBalance(user2),
            expectedClaimableAmount2
        );
        // as user3 has not done any withdrawls
        assertEq(xCitadelVester.claimableBalance(user3), 0);

        // minting again
        vm.warp(block.timestamp + 2000);

        vm.prank(policyOps);
        citadelMinter.mintAndDistribute();

        uint256 user2AmountMinting3 = (xCitadel.balance() *
            xCitadel.balanceOf(user2)) / xCitadel.totalSupply();
        uint256 user3AmountMinting3 = (
            (xCitadel.balance() * xCitadel.balanceOf(user3))
        ) / xCitadel.totalSupply();

        // user2 has withdrawn only some amount, user1 still have shares
        assertTrue(user2AmountMinting2 > 0);
        // user3 should have more than compare to minting cycle 2
        assertTrue(user3AmountMinting3 > user3AmountMinting2);

        // all users claim the amount they should get expected
        uint256 userBalanceBefore = citadel.balanceOf(user1);
        vm.prank(user1);
        xCitadelVester.claim(user1, user1AmountMinting1);
        uint256 userBalanceAfter = citadel.balanceOf(user1);

        // user1 has withdrawn all amount
        assertEq(userBalanceAfter - userBalanceBefore, user1AmountMinting1);
        userBalanceBefore = citadel.balanceOf(user2);
        vm.prank(user2);
        xCitadelVester.claim(user2, expectedClaimableAmount2);
        userBalanceAfter = citadel.balanceOf(user2);

        // user2 has withdrawn some amount
        assertEq(
            userBalanceAfter - userBalanceBefore,
            expectedClaimableAmount2
        );

        userBalanceBefore = citadel.balanceOf(user3);
        vm.prank(user3);
        xCitadelVester.claim(user3, 10e18);
        userBalanceAfter = citadel.balanceOf(user3);

        // user3 has not withdrawn anything
        assertEq(userBalanceAfter, userBalanceBefore);
    }

    /*
    Tests checks - 
        - Total Supply of xCTDL increases as citadel is deposited in locker
        - ppfs will increase as citadel is deposited into staking contract
    */
    function mintAndDistribute() public {
        uint256 pricePerShareBefore = xCitadel.getPricePerFullShare();
        vm.startPrank(policyOps);
        citadelMinter.setCitadelDistributionSplit(0, 6000, 4000, 0);

        vm.stopPrank();
        vm.startPrank(governance);
        schedule.setMintingStart(block.timestamp);
        citadelMinter.initializeLastMintTimestamp();
        vm.stopPrank();

        vm.warp(block.timestamp + 1000);

        uint256 expectedMint = schedule.getMintable(
            citadelMinter.lastMintTimestamp()
        );

        uint256 xCitadelTotalSupplyBefore = xCitadel.totalSupply();
        uint256 citadelBeforeInXcitadel = xCitadel.balance();

        vm.prank(policyOps);
        citadelMinter.mintAndDistribute();

        uint256 expectedToStakers = (expectedMint * 6000) / 10000;
        uint256 expectedToLockers = (expectedMint * 4000) / 10000;
        uint256 xCitadelTotalSupplyAfter = xCitadel.totalSupply();
        uint256 citadelAfterInXcitadel = xCitadel.balance();
        uint256 pricePerShareAfter = xCitadel.getPricePerFullShare();

        // total supply should increase as the amount is deposited
        assertEq(
            xCitadelTotalSupplyAfter - xCitadelTotalSupplyBefore,
            expectedToLockers
        );

        // balance should increase as expectedToLockers is deposited.
        // And expectedToStakers is transferred to xCitadel.
        assertEq(
            citadelAfterInXcitadel - citadelBeforeInXcitadel,
            expectedToLockers + expectedToStakers
        );

        // price per share should increase
        assertEq(
            pricePerShareAfter - pricePerShareBefore,
            (expectedToStakers * 1e18) / xCitadelTotalSupplyAfter
        );
    }

    /*
    Tests for bricked strategy
    */

    function testBrickedStrategy() public {
        address user = address(1);
        TestInfo memory info;

        // giving user some citadel to stake
        vm.prank(governance);
        citadel.mint(user, 10e18);
        assertEq(citadel.balanceOf(user), 10e18);

        // User stakes CTDL
        info.userCitadelBefore = citadel.balanceOf(user);
        info.xCitadelBalanceBefore = xCitadel.balance();
        info.userXCitadelBefore = xCitadel.balanceOf(user);
        info.xCitadelTotalSupplyBefore = xCitadel.totalSupply();

        vm.startPrank(user);
        // approve staking amount
        citadel.approve(address(xCitadel), 10e18);
        // deposit
        xCitadel.deposit(10e18);
        vm.stopPrank();

        info.userCitadelAfter = citadel.balanceOf(user);
        info.xCitadelBalanceAfter = xCitadel.balance();
        info.userXCitadelAfter = xCitadel.balanceOf(user);
        info.xCitadelTotalSupplyAfter = xCitadel.totalSupply();

        // check if user has successfully deposited
        assertEq(info.userCitadelBefore - info.userCitadelAfter, 10e18);
        assertEq(info.userXCitadelAfter - info.userXCitadelBefore, 10e18); // user should have got same amount as totalSupply was zero
        assertEq(info.xCitadelBalanceAfter - info.xCitadelBalanceBefore, 10e18); // xCitadel should have some citadel
        assertEq(
            info.xCitadelTotalSupplyAfter - info.xCitadelTotalSupplyBefore,
            10e18
        ); // total supply should have incremented

        // Earning transfers available amount of CTDL from Staker to Strategy
        info.xCitadelBalanceBefore = xCitadel.balance();
        info.xCitadelTotalSupplyBefore = xCitadel.totalSupply();
        info.strategyCitadelBefore = citadel.balanceOf(
            address(xCitadel_strategy)
        );
        info.vaultCitadelBefore = citadel.balanceOf(address(xCitadel));

        info.available = xCitadel.available();

        vm.prank(governance);
        xCitadel.earn();

        info.xCitadelBalanceAfter = xCitadel.balance();
        info.xCitadelTotalSupplyAfter = xCitadel.totalSupply();
        info.strategyCitadelAfter = citadel.balanceOf(
            address(xCitadel_strategy)
        );
        info.vaultCitadelAfter = citadel.balanceOf(address(xCitadel));

        // check earn accounting
        assertEq(info.xCitadelBalanceBefore, info.xCitadelBalanceAfter); // xCitadel's balance() remains unchanged
        assertEq(info.xCitadelTotalSupplyBefore, info.xCitadelTotalSupplyAfter); // xCitadel's totalSupply() remains unchanged
        assertEq(
            info.strategyCitadelAfter - info.strategyCitadelBefore,
            info.available
        ); // Available amount was transferred to strat
        assertEq(
            info.vaultCitadelBefore - info.vaultCitadelAfter,
            info.available
        ); // total supply should have incremented
        assertEq(xCitadel_strategy.balanceOf(), info.available); // Strategy's total balance equals the received amount

        // User can withdraw from vault while most assets are on the strategy
        info.vestingCitadelBefore = citadel.balanceOf(address(xCitadelVester));
        info.xCitadelBalanceBefore = xCitadel.balance();
        info.strategyCitadelBefore = citadel.balanceOf(
            address(xCitadel_strategy)
        );
        info.vaultCitadelBefore = citadel.balanceOf(address(xCitadel));

        // User withdraws half of position
        vm.prank(user);
        xCitadel.withdraw(5e18);

        info.vestingCitadelAfter = citadel.balanceOf(address(xCitadelVester));
        info.xCitadelBalanceAfter = xCitadel.balance();
        info.strategyCitadelAfter = citadel.balanceOf(
            address(xCitadel_strategy)
        );
        info.vaultCitadelAfter = citadel.balanceOf(address(xCitadel));

        // Check withdraw accounting
        assertEq(
            info.strategyCitadelBefore - info.strategyCitadelAfter,
            5e18 - info.vaultCitadelBefore
        ); // Required - amount idle on vault
        assertEq(
            info.vaultCitadelBefore - info.vaultCitadelAfter,
            info.vaultCitadelBefore
        ); // All CTDL on vault is transferred
        assertEq(info.vestingCitadelAfter - info.vestingCitadelBefore, 5e18); // Amount required is transferred to vesting
        assertEq(info.xCitadelBalanceBefore - info.xCitadelBalanceAfter, 5e18); // Total balance decreases by required amount

        // Governance can withdraw all want from strat into the vault
        info.xCitadelBalanceBefore = xCitadel.balance();
        info.strategyCitadelBefore = citadel.balanceOf(
            address(xCitadel_strategy)
        );
        info.vaultCitadelBefore = citadel.balanceOf(address(xCitadel));

        assertEq(info.strategyCitadelBefore, 5e18); // Strat holds remaining total CTDL amount

        // Governance calls withdrawToVault
        vm.prank(governance);
        xCitadel.withdrawToVault();

        info.xCitadelBalanceAfter = xCitadel.balance();
        info.strategyCitadelAfter = citadel.balanceOf(
            address(xCitadel_strategy)
        );
        info.vaultCitadelAfter = citadel.balanceOf(address(xCitadel));

        // Check withdrawToVault accounting
        assertEq(xCitadel_strategy.balanceOf(), 0); // No more want on strat
        assertEq(info.xCitadelBalanceBefore, info.xCitadelBalanceAfter); // xCitadel's balance() remains unchanged
        assertEq(
            info.strategyCitadelBefore - info.strategyCitadelAfter,
            info.strategyCitadelBefore
        ); // All CTDL on strat is transferred
        assertEq(
            info.vaultCitadelAfter - info.vaultCitadelBefore,
            info.strategyCitadelBefore
        ); // All CTDL on strat is transferred to vault
    }
}
