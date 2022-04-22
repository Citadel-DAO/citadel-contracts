pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "../interfaces/badger/IBadgerVipGuestlist.sol";

contract GlobalAccessControlTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testPauseAndUnPause() public{
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

    function testFundingPausingFunctions() public{

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
        fundingCvx.setCitadelAssetPriceBounds(1e18, 100e18);

        vm.expectRevert("local-paused");
        fundingCvx.updateCitadelPriceInAsset();

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
        fundingCvx.setCitadelAssetPriceBounds(1e18, 100e18);

        vm.expectRevert("global-paused");
        fundingCvx.updateCitadelPriceInAsset();
    }

    function testMintingPausingFunction() public{
        // pausing locally
        vm.prank(guardian);
        citadelMinter.pause();

        vm.startPrank(policyOps);
        vm.expectRevert("local-paused");
        citadelMinter.mintAndDistribute();

        vm.expectRevert("local-paused");
        citadelMinter.setFundingPoolWeight(address(fundingCvx), 6000);

        vm.expectRevert("local-paused");
        citadelMinter.setCitadelDistributionSplit(1000, 5000, 4000);

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
        citadelMinter.setCitadelDistributionSplit(1000, 5000, 4000);

        vm.stopPrank();

        vm.prank(governance);
        vm.expectRevert("global-paused");
        citadelMinter.initializeLastMintTimestamp();

    }

    function testKnightingRoundPausingFunction() public{
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

    function testStakedCitadel() public{
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

    function testSchedulePausing() public{
        vm.prank(guardian);
        schedule.pause();

        vm.startPrank(governance);
        vm.expectRevert(bytes("local-paused"));
        schedule.setMintingStart(block.timestamp + 1000);

        vm.expectRevert(bytes("local-paused"));
        schedule.setEpochRate(8 , 10);

        vm.stopPrank();

        vm.prank(guardian);
        gac.pause();
        vm.startPrank(governance);
        vm.expectRevert(bytes("global-paused"));
        schedule.setMintingStart(block.timestamp + 1000);

        vm.expectRevert(bytes("global-paused"));
        schedule.setEpochRate(8 , 10);

        vm.stopPrank();

    }
}