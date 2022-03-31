// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {AddressUpgradeable} from "openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {EnumerableSetUpgradeable} from "openzeppelin-contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./lib/GlobalAccessControlManaged.sol";

import "./interfaces/citadel/ISupplySchedule.sol";
import "./interfaces/citadel/ICitadelToken.sol";
import "./interfaces/citadel/IxCitadel.sol";
import "./interfaces/citadel/IxCitadelLocker.sol";

/**
Supply schedules are defined in terms of Epochs
*/
contract CitadelMinter is GlobalAccessControlManaged, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE =
        keccak256("POLICY_OPERATIONS_ROLE");

    address public citadelToken;
    address public xCitadel;
    IxCitadelLocker public xCitadelLocker;
    address public supplySchedule;

    uint256 public lastMintTimestamp;

    uint256 constant MAX_BPS = 10000;

    EnumerableSetUpgradeable.AddressSet internal fundingPools;
    mapping (address => uint) public fundingPoolWeights;
    uint public totalFundingPoolWeight;

    uint public fundingBps;
    uint public stakingBps;
    uint public lockingBps;
    
    event FundingPoolWeightSet(address pool, uint weight, uint totalFundingPoolWeight);
    event CitadelDistributionSplitSet(uint fundingBps, uint stakingBps, uint lockingBps);
    event CitadelDistribution(uint fundingAmount, uint stakingAmount, uint lockingAmount);

    event CitadelDistributionToFunding(uint startTime, uint endTime, uint citadelAmount);
    event CitadelDistributionToFundingPool(uint startTime, uint endTime, address pool, uint citadelAmount);
    event CitadelDistributionToStaking(uint startTime, uint endTime, uint citadelAmount);
    event CitadelDistributionToLocking(uint startTime, uint endTime, uint citadelAmount, uint xCitadelAmount);

    function initialize(
        address _gac,
        address _citadelToken,
        address _xCitadel,
        address _xCitadelLocker,
        address _supplySchedule
    ) external initializer {
        require(_gac != address(0), "address 0 invalid");
        require(_citadelToken != address(0), "address 0 invalid");
        require(_xCitadel != address(0), "address 0 invalid");
        require(_xCitadelLocker != address(0), "address 0 invalid");
        require(_supplySchedule != address(0), "address 0 invalid");

        __GlobalAccessControlManaged_init(_gac);
        __ReentrancyGuard_init();

        citadelToken = _citadelToken;
        xCitadel = _xCitadel;
        xCitadelLocker = IxCitadelLocker(_xCitadelLocker);

        supplySchedule = _supplySchedule;

        // Approve xCitadel vault for use of citadel tokens
        IERC20Upgradeable(citadelToken).approve(xCitadel, type(uint256).max);
        // Approve xCitadel for locker to use
        IERC20Upgradeable(xCitadel).approve(_xCitadelLocker, type(uint256).max);
    }

    function initializeLastMintTimestamp() external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {
        require(lastMintTimestamp == 0, "CitadelMinter: last mint timestamp already initialized");
        uint globalStartTimestamp = ISupplySchedule(supplySchedule).globalStartTimestamp();

        require(globalStartTimestamp >= 0, "CitadelMinter: supply schedule start not initialized");
        lastMintTimestamp = globalStartTimestamp;
    }

    // @dev Set the funding weight for a given address. 
    // @dev Verification on the address is performed via a proper return value on a citadelContractType() call. 
    // @dev setting funding pool weight to 0 for an existing pool will delete it from the list
    function setFundingPoolWeight(address _pool, uint _weight) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable {
        bool poolExists = fundingPools.contains(_pool);
        // Remove existing pool on 0 weight
        if (_weight == 0 && poolExists) {
            fundingPoolWeights[_pool] = 0;
            totalFundingPoolWeight = totalFundingPoolWeight - fundingPoolWeights[_pool];
            _removeFundingPool(_pool);

            emit FundingPoolWeightSet(_pool, _weight, totalFundingPoolWeight);
        } else {
            // Add new pool or modify existing pool
            require(_weight <= 10000, "exceed max funding pool weight");
            if (!poolExists) {
                _addFundingPool(_pool);
            }
            uint _newTotalWeight = totalFundingPoolWeight;
            _newTotalWeight = _newTotalWeight - fundingPoolWeights[_pool];
            fundingPoolWeights[_pool] = _weight;
            _newTotalWeight = _newTotalWeight + _weight;
            totalFundingPoolWeight = _newTotalWeight;

            emit FundingPoolWeightSet(_pool, _weight, _newTotalWeight);
        }
    }

    function setCitadelDistributionSplit(
        uint256 _fundingBps,
        uint256 _stakingBps,
        uint256 _lockingBps
    ) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable nonReentrant {
        require(_fundingBps.add(_stakingBps).add(_lockingBps) == MAX_BPS, "Sum of split values must be 10000 bps");
        fundingBps = _fundingBps;
        stakingBps = _stakingBps;
        lockingBps = _lockingBps;

        emit CitadelDistributionSplitSet(_fundingBps, _stakingBps, _lockingBps);
    }

    /// @dev Auto-compound staker amount into xCTDL
    function mintAndDistribute() external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable nonReentrant {

        // debug setup, ignore for audit and review
        // uint mintable = 1e18;
        // ISupplySchedule(supplySchedule).getMintableDebug();

        uint mintable = ISupplySchedule(supplySchedule).getMintable(lastMintTimestamp);
        ICitadelToken(citadelToken).mint(address(this), mintable);

        uint lockingAmount = 0;
        uint stakingAmount = 0;
        uint fundingAmount = 0;

        uint startTime = lastMintTimestamp;
        uint endTime = block.timestamp;

        if (lockingBps != 0) {
            lockingAmount = mintable.mul(lockingBps).div(MAX_BPS);
            uint256 beforeAmount = IERC20Upgradeable(xCitadel).balanceOf(
                address(this)
            );

            IxCitadel(xCitadel).deposit(lockingAmount);

            uint256 afterAmount = IERC20Upgradeable(xCitadel).balanceOf(
                address(this));
            
            uint256 xCitadelToLockers = afterAmount - beforeAmount;

            xCitadelLocker.notifyRewardAmount(
                xCitadel,
                xCitadelToLockers
                );
            emit CitadelDistributionToLocking(lastMintTimestamp, block.timestamp, lockingAmount, xCitadelToLockers);
        }

        if (stakingBps != 0) {
            stakingAmount = mintable.mul(stakingBps).div(MAX_BPS);

            IERC20Upgradeable(citadelToken).transfer(xCitadel, stakingAmount);
            emit CitadelDistributionToStaking(lastMintTimestamp, block.timestamp, stakingAmount);
        }

        if (fundingBps != 0) {
            fundingAmount = mintable.mul(fundingBps).div(MAX_BPS);

            _transferToFundingPools(fundingAmount);
            emit CitadelDistributionToFunding(lastMintTimestamp, block.timestamp, fundingAmount);
        }

        emit CitadelDistribution(fundingAmount, stakingAmount, lockingAmount);

        lastMintTimestamp = block.timestamp;
    }

    // ===== Internal Functions =====

    // === Funding Pool Management ===
    function _transferToFundingPools(uint _citadelAmount) internal {
        require(fundingPools.length() > 0, "CitadelMinter: no funding pools");
        for (uint i = 0; i < fundingPools.length(); i++) {
            address pool = fundingPools.at(i);
            uint weight = fundingPoolWeights[pool];

            uint amount = _citadelAmount.mul(weight).div(totalFundingPoolWeight);

            IERC20Upgradeable(citadelToken).safeTransfer(
                pool,
                amount
            );

            emit CitadelDistributionToFundingPool(lastMintTimestamp, block.timestamp, pool, amount);
        }
    }

    function getFundingPoolWeights() external view returns (address[] memory pools, uint[] memory weights) {
        uint numPools = fundingPools.length();
        pools = new address[](numPools);
        weights = new uint[](numPools);

        for (uint i = 0; i < numPools; i++) {
            address pool = fundingPools.at(i);
            uint weight = fundingPoolWeights[pool];

            pools[i] = pool;
            weights[i] = weight;
        }
    }

    function _removeFundingPool(address _pool) internal {
        require(fundingPools.remove(_pool), "funding pool does not exist for removal");
    }

    function _addFundingPool(address _pool) internal {
        require(fundingPools.add(_pool), "funding pool already exists");
    }


}
