pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "../interfaces/badger/IBadgerVipGuestlist.sol";

contract GlobalAccessControlTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testPauseAndUnPausing() public {
        vm.prank(address(1));
        vm.expectRevert("PAUSER_ROLE");
        gac.pause();

        // PAUSER_ROLE is assigned to guardian in BaseFixture
        vm.prank(guardian);
        gac.pause();

        // check if it paused
        assertTrue(gac.paused());

        vm.prank(address(1));
        vm.expectRevert("UNPAUSER_ROLE");
        gac.unpause();

        // UNPAUSER_ROLE is assigned to techOps in BaseFixture
        vm.prank(techOps);
        gac.unpause();

        // check if it unpaused
        assertTrue(!gac.paused());
    }

    function testFundingPausing() public {
        // pausing locally
        vm.prank(guardian);
        fundingCvx.pause();

        vm.expectRevert("local-paused");
        fundingCvx.deposit(1e18, 0);

        vm.expectRevert("local-paused");
        fundingCvx.setDiscount(1000);

        vm.expectRevert("local-paused");
        fundingCvx.clearCitadelPriceFlag();

        vm.expectRevert("local-paused");
        fundingCvx.setAssetCap(100e18);

        vm.expectRevert("local-paused");
        fundingCvx.sweep(address(cvx));

        vm.expectRevert("local-paused");
        fundingCvx.claimAssetToTreasury();

        vm.expectRevert("local-paused");
        fundingCvx.setDiscountLimits(1000, 6000);

        vm.expectRevert("local-paused");
        fundingCvx.setDiscountManager(address(2));

        vm.expectRevert("local-paused");
        fundingCvx.setSaleRecipient(address(2));

        vm.expectRevert("local-paused");
        fundingCvx.setCitadelPerAssetBounds(1e18, 100e18);

        vm.expectRevert("local-paused");
        fundingCvx.updateCitadelPerAsset();

        // pausing globally
        vm.prank(guardian);
        gac.pause();

        vm.expectRevert("global-paused");
        fundingCvx.deposit(1e18, 0);

        vm.expectRevert("global-paused");
        fundingCvx.setDiscount(1000);

        vm.expectRevert("global-paused");
        fundingCvx.clearCitadelPriceFlag();

        vm.expectRevert("global-paused");
        fundingCvx.setAssetCap(100e18);

        vm.expectRevert("global-paused");
        fundingCvx.sweep(address(cvx));

        vm.expectRevert("global-paused");
        fundingCvx.claimAssetToTreasury();

        vm.expectRevert("global-paused");
        fundingCvx.setDiscountLimits(1000, 6000);

        vm.expectRevert("global-paused");
        fundingCvx.setDiscountManager(address(2));

        vm.expectRevert("global-paused");
        fundingCvx.setSaleRecipient(address(2));

        vm.expectRevert("global-paused");
        fundingCvx.setCitadelPerAssetBounds(1e18, 100e18);

        vm.expectRevert("global-paused");
        fundingCvx.updateCitadelPerAsset();
    }

    function testMintingPausing() public {
        // pausing locally
        vm.prank(guardian);
        citadelMinter.pause();

        vm.startPrank(policyOps);
        vm.expectRevert("local-paused");
        citadelMinter.mintAndDistribute();

        vm.expectRevert("local-paused");
        citadelMinter.setFundingPoolWeight(address(fundingCvx), 6000);

        vm.expectRevert("local-paused");
        citadelMinter.setCitadelDistributionSplit(1000, 5000, 3000, 1000);

        vm.stopPrank();

        vm.prank(governance);
        vm.expectRevert("local-paused");
        citadelMinter.initializeLastMintTimestamp();

        // pausing globally
        vm.prank(guardian);
        gac.pause();

        vm.startPrank(policyOps);
        vm.expectRevert("global-paused");
        citadelMinter.mintAndDistribute();

        vm.expectRevert("global-paused");
        citadelMinter.setFundingPoolWeight(address(fundingCvx), 6000);

        vm.expectRevert("global-paused");
        citadelMinter.setCitadelDistributionSplit(1000, 5000, 3000, 1000);

        vm.stopPrank();

        vm.prank(governance);
        vm.expectRevert("global-paused");
        citadelMinter.initializeLastMintTimestamp();
    }

    function testKnightingRoundPausing() public {
        // pausing locally
        vm.prank(guardian);
        knightingRound.pause();

        bytes32[] memory emptyProof = new bytes32[](1);
        vm.expectRevert("local-paused");
        knightingRound.buy(1e8, 0, emptyProof);

        vm.expectRevert("local-paused");
        knightingRound.claim();

        vm.expectRevert("local-paused");
        knightingRound.sweep(address(cvx));

        // pausing globally
        vm.prank(guardian);
        gac.pause();

        vm.expectRevert("global-paused");
        knightingRound.buy(1e8, 0, emptyProof);

        vm.expectRevert("global-paused");
        knightingRound.claim();

        vm.expectRevert("global-paused");
        knightingRound.sweep(address(cvx));
    }

    function testKnightingRoundEthPausing() public {
        // pausing locally
        vm.prank(guardian);
        knightingRoundWithEth.pause();

        bytes32[] memory emptyProof = new bytes32[](1);

        vm.startPrank(shrimp);
        vm.expectRevert("local-paused");
        knightingRoundWithEth.buyEth{value: address(shrimp).balance / 2}(
            0,
            emptyProof
        );

        vm.expectRevert("local-paused");
        knightingRoundWithEth.claim();
        vm.stopPrank();

        vm.startPrank(treasuryOps);
        vm.expectRevert("local-paused");
        knightingRoundWithEth.sweep(address(cvx));
        vm.stopPrank();

        // pausing globally
        vm.prank(guardian);
        gac.pause();

        vm.startPrank(shrimp);
        vm.expectRevert("global-paused");
        knightingRoundWithEth.buyEth{value: address(shrimp).balance / 2}(
            0,
            emptyProof
        );

        vm.expectRevert("global-paused");
        knightingRoundWithEth.claim();
        vm.stopPrank();

        vm.startPrank(treasuryOps);
        vm.expectRevert("global-paused");
        knightingRoundWithEth.sweep(address(cvx));
        vm.stopPrank();
    }

    function testStakedCitadelPausing() public {
        vm.prank(guardian);
        xCitadel.pause();

        bytes32[] memory emptyProof = new bytes32[](1);

        vm.expectRevert("Pausable: paused");
        xCitadel.deposit(1e18);

        vm.expectRevert("Pausable: paused");
        xCitadel.deposit(1e18, emptyProof);

        vm.expectRevert("Pausable: paused");
        xCitadel.depositAll();

        vm.expectRevert("Pausable: paused");
        xCitadel.depositAll(emptyProof);

        vm.expectRevert("Pausable: paused");
        xCitadel.depositFor(address(1), 1e18);

        vm.expectRevert("Pausable: paused");
        xCitadel.depositFor(address(1), 1e18, emptyProof);

        vm.expectRevert("Pausable: paused");
        xCitadel.withdraw(1000);

        vm.expectRevert("Pausable: paused");
        xCitadel.withdrawAll();

        vm.expectRevert("Pausable: paused");
        xCitadel.setTreasury(address(1));

        vm.expectRevert("Pausable: paused");
        xCitadel.setStrategy(address(1));

        vm.expectRevert("Pausable: paused");
        xCitadel.setToEarnBps(100);

        vm.expectRevert("Pausable: paused");
        xCitadel.setGuestList(address(1));

        vm.expectRevert("Pausable: paused");
        xCitadel.setWithdrawalFee(1000);

        vm.expectRevert("Pausable: paused");
        xCitadel.setPerformanceFeeGovernance(1000);

        vm.expectRevert("Pausable: paused");
        xCitadel.setManagementFee(1000);
    }

    function testStakedCitadelVesterPausing() public {
        vm.prank(guardian);
        xCitadelVester.pause();

        vm.startPrank(governance);
        vm.expectRevert("local-paused");
        xCitadelVester.claim(address(1), 1e18);

        vm.expectRevert("local-paused");
        xCitadelVester.setupVesting(address(1), 1e18, 1651244600);

        vm.expectRevert("local-paused");
        xCitadelVester.setVestingDuration(86400);
        vm.stopPrank();

        vm.prank(techOps);
        xCitadelVester.unpause();

        vm.prank(guardian);
        gac.pause();

        vm.startPrank(governance);
        vm.expectRevert("global-paused");
        xCitadelVester.claim(address(1), 1e18);

        vm.expectRevert("global-paused");
        xCitadelVester.setupVesting(address(1), 1e18, 1651244600);

        vm.expectRevert("global-paused");
        xCitadelVester.setVestingDuration(86400);
        vm.stopPrank();
    }

    function testSchedulePausing() public {
        vm.prank(guardian);
        schedule.pause();

        vm.startPrank(governance);
        vm.expectRevert(bytes("local-paused"));
        schedule.setMintingStart(block.timestamp + 1000);

        vm.expectRevert(bytes("local-paused"));
        schedule.setEpochRate(8, 10);

        vm.stopPrank();

        vm.prank(guardian);
        gac.pause();
        vm.startPrank(governance);
        vm.expectRevert(bytes("global-paused"));
        schedule.setMintingStart(block.timestamp + 1000);

        vm.expectRevert(bytes("global-paused"));
        schedule.setEpochRate(8, 10);

        vm.stopPrank();
    }

    function testFundingCallerRoles() public {
        // calling with wrong address
        vm.expectRevert(bytes("GAC: invalid-caller-role"));
        fundingCvx.setDiscountLimits(0, 20);
        vm.prank(address(governance));
        fundingCvx.setDiscountLimits(10, 50);

        // calling from wrong account
        vm.expectRevert(bytes("GAC: invalid-caller-role-or-address"));
        fundingCvx.setDiscount(20);
        vm.prank(address(policyOps)); // calling from correct account
        fundingCvx.setDiscount(20);
        (, , , address discountManager, , ) = fundingCvx.funding();
        vm.prank(discountManager);
        fundingCvx.setDiscount(30);

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.setAssetCap(10e18);
        // setting asset cap from correct account
        vm.prank(policyOps);
        fundingCvx.setAssetCap(1000e18);

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.claimAssetToTreasury();
        erc20utils.forceMintTo(address(fundingCvx), address(cvx), 100e18); // give some amount to fundingCvx
        vm.prank(treasuryOps);
        fundingCvx.claimAssetToTreasury();

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.sweep(address(cvx));
        erc20utils.forceMintTo(address(fundingCvx), address(wbtc), 100e8); // give some wbtc to fundingCvx
        vm.prank(treasuryOps);
        fundingCvx.sweep(address(wbtc));

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.setDiscountManager(address(2));
        // setting discountManager from correct account
        vm.prank(governance);
        fundingCvx.setDiscountManager(address(2));

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.updateCitadelPerAsset();
        vm.startPrank(keeper);
        medianOracleCvx.pushReport(1000);
        fundingCvx.updateCitadelPerAsset();
        vm.stopPrank();

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.setSaleRecipient(address(2));
        // setting setSaleRecipient from correct account
        vm.prank(governance);
        fundingCvx.setSaleRecipient(address(2));

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.setCitadelPerAssetBounds(0, 5000);
        vm.prank(governance);
        fundingCvx.setCitadelPerAssetBounds(0, 5000);

        vm.expectRevert("GAC: invalid-caller-role");
        fundingCvx.clearCitadelPriceFlag();
        // setting setSaleRecipient from correct account
        vm.prank(policyOps);
        fundingCvx.clearCitadelPriceFlag();
    }

    function testMintingAndScheduleCallerRoles() public {
        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.setCitadelDistributionSplit(5000, 3000, 1000, 1000);
        vm.prank(policyOps);
        citadelMinter.setCitadelDistributionSplit(5000, 2500, 1000, 1500);

        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.setFundingPoolWeight(address(fundingCvx), 1000);
        vm.prank(policyOps);
        citadelMinter.setFundingPoolWeight(address(fundingCvx), 2000);

        vm.expectRevert("GAC: invalid-caller-role");
        schedule.setEpochRate(7, 10e5);
        vm.prank(governance);
        schedule.setEpochRate(7, 10e5);

        vm.expectRevert("GAC: invalid-caller-role");
        schedule.setMintingStart(1000);
        vm.prank(governance);
        schedule.setMintingStart(block.timestamp);

        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.initializeLastMintTimestamp();
        vm.prank(governance);
        citadelMinter.initializeLastMintTimestamp();

        vm.warp(block.timestamp + 100);
        vm.expectRevert("GAC: invalid-caller-role");
        citadelMinter.mintAndDistribute();
        vm.prank(policyOps);
        citadelMinter.mintAndDistribute();
    }

    function testKnightingRoundCallerRoles() public {
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setSaleStart(block.timestamp);
        // calling with correct role
        vm.prank(governance);
        knightingRound.setSaleStart(block.timestamp);

        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setSaleDuration(8 days);
        // calling with correct role
        vm.prank(governance);
        knightingRound.setSaleDuration(8 days);

        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setTokenInLimit(25e8);
        // calling with correct role
        vm.prank(techOps);
        knightingRound.setTokenInLimit(25e8);

        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setTokenOutPerTokenIn(25e18);
        vm.prank(governance);
        knightingRound.setTokenOutPerTokenIn(25e18);

        // calling from different account
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setSaleRecipient(address(2));
        vm.prank(governance);
        knightingRound.setSaleRecipient(address(2));

        // tests for setGuestlist
        vm.prank(address(1));
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.setGuestlist(address(3));
        vm.prank(techOps);
        knightingRound.setGuestlist(address(3));

        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.sweep(address(xCitadel));
        // treasuryOps should be able to sweep any amount of any token other than xCTDL
        erc20utils.forceMintTo(address(knightingRound), address(wbtc), 10e8);
        vm.prank(treasuryOps);
        knightingRound.sweep(address(wbtc));

        vm.warp(block.timestamp + knightingRound.saleDuration());
        vm.expectRevert("GAC: invalid-caller-role");
        knightingRound.finalize();
        vm.prank(governance);
        knightingRound.finalize();
    }

    function testVestingCallerRoles() public {
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelVester.setVestingDuration(8 days);
        vm.prank(governance);
        xCitadelVester.setVestingDuration(8 days);
    }

    function testStakingCallerRoles() public {
        vm.expectRevert("onlyPausers"); // nly guardian and governance can pause
        xCitadel.pauseDeposits();

        vm.prank(governance);
        xCitadel.pauseDeposits();

        vm.prank(guardian); // guardian is also pauser
        xCitadel.pauseDeposits();

        vm.expectRevert("onlyGovernance");
        xCitadel.unpauseDeposits();

        vm.prank(governance); // only governance can unpause deposits
        xCitadel.unpauseDeposits();

        vm.expectRevert("onlyPausers"); // only guardian and governance can pause
        xCitadel.pause();

        vm.prank(governance);
        xCitadel.pause();

        vm.prank(governance);
        xCitadel.unpause();

        vm.prank(guardian); // guardian is also pauser
        xCitadel.pause();

        vm.expectRevert("onlyGovernance");
        xCitadel.unpause();

        vm.prank(governance);
        xCitadel.unpause();

        vm.expectRevert("onlyStrategy");
        xCitadel.reportHarvest(0);

        vm.prank(address(xCitadel_strategy));
        xCitadel.reportHarvest(0);

        vm.expectRevert("onlyStrategy");
        xCitadel.reportAdditionalToken(address(citadel));

        vm.prank(address(xCitadel_strategy));
        xCitadel.reportAdditionalToken(address(wbtc));

        vm.expectRevert("onlyAuthorizedActors"); // authorized actors are keeper and governance
        xCitadel.earn();

        vm.prank(keeper); // keeper can call earn
        xCitadel.earn();

        vm.prank(governance); // governance can call earn
        xCitadel.earn();

        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.setToEarnBps(0);
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.setGuestList(address(0));
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.setWithdrawalFee(0);
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.setPerformanceFeeStrategist(0);
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.setPerformanceFeeGovernance(0);
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.setManagementFee(0);
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.withdrawToVault();
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.emitNonProtectedToken(address(citadel));
        vm.expectRevert("onlyGovernanceOrStrategist");
        xCitadel.sweepExtraToken(address(wbtc));

        vm.startPrank(governance); // governance can call all these functions
        xCitadel.setToEarnBps(0);
        xCitadel.setGuestList(address(0));
        xCitadel.setWithdrawalFee(0);
        xCitadel.setPerformanceFeeStrategist(0);
        xCitadel.setPerformanceFeeGovernance(0);
        xCitadel.setManagementFee(0);
        xCitadel.withdrawToVault();
        xCitadel.sweepExtraToken(address(wbtc));
        vm.stopPrank();

        address strategist = xCitadel_strategy.strategist();
        vm.startPrank(strategist); // strategist can call all these functions
        xCitadel.setToEarnBps(0);
        xCitadel.setGuestList(address(0));
        xCitadel.setWithdrawalFee(0);
        xCitadel.setPerformanceFeeStrategist(0);
        xCitadel.setPerformanceFeeGovernance(0);
        xCitadel.setManagementFee(0);
        xCitadel.withdrawToVault();
        xCitadel.sweepExtraToken(address(wbtc));
        vm.stopPrank();

        vm.expectRevert("onlyGovernance");
        xCitadel.setTreasury(address(treasuryVault));
        vm.expectRevert("onlyGovernance");
        xCitadel.setStrategy(address(xCitadel_strategy));
        vm.expectRevert("onlyGovernance");
        xCitadel.setMaxWithdrawalFee(0);
        vm.expectRevert("onlyGovernance");
        xCitadel.setMaxPerformanceFee(0);
        vm.expectRevert("onlyGovernance");
        xCitadel.setMaxManagementFee(0);
        vm.expectRevert("onlyGovernance");
        xCitadel.setGuardian(guardian);
        vm.expectRevert("onlyGovernance");
        xCitadel.setVesting(address(xCitadelVester));

        vm.startPrank(governance); // governance can call all these functions
        xCitadel.setTreasury(address(treasuryVault));
        xCitadel.setStrategy(address(xCitadel_strategy));
        xCitadel.setMaxWithdrawalFee(0);
        xCitadel.setMaxPerformanceFee(0);
        xCitadel.setMaxManagementFee(0);
        xCitadel.setGuardian(guardian);
        xCitadel.setVesting(address(xCitadelVester));
        vm.stopPrank();
    }
}
