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

    uint256 constant MAX_BPS = 10000;

    EnumerableSetUpgradeable.AddressSet internal fundingPools;
    mapping (address => uint) fundingPoolWeights;
    uint totalFundingPoolWeight;

    event FundingPoolWeightSet(uint weight, bool increased, uint diff, uint totalFundingPoolWeight);

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
        IERC20Upgradeable(citadelToken).approve(xCitadel, 2**256 - 1);
        // Approve xCitadel for locker to use
        IERC20Upgradeable(xCitadel).approve(_xCitadelLocker, 2**256 - 1);
    }

    // @dev Set the funding weight for a given address. 
    // @dev Verification on the address is performed via a proper return value on a citadelContractType() call. 
    // @dev setting funding pool weight to 0 for an existing pool will delete it from the list
    function setFundingPoolWeight(address _pool, uint _weight) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable {
        bool poolExists = fundingPools.contains(_pool);
        // Remove existing pool on 0 weight
        if (_weight == 0 && poolExists) {
            _setFundingPoolWeight(_pool, 0);
            _removeFundingPool(_pool);
        } else {
            require(_weight <= 10000, "exceed max funding pool weight");
            if (!poolExists) {
                _addFundingPool(_pool);
            }
            _setFundingPoolWeight(_pool, _weight);
        }
    }

    /// @dev Auto-compound staker amount into xCTDL
    function mintAndDistribute(
        uint256 _fundingBps,
        uint256 _stakingBps,
        uint256 _lockingBps
    ) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable nonReentrant {
        require(_fundingBps.add(_stakingBps).add(_lockingBps) == MAX_BPS);

        uint mintable = ISupplySchedule(supplySchedule).getMintable();
        ICitadelToken(citadelToken).mint(address(this), mintable);

        if (_lockingBps != 0) {
            uint lockingAmount = mintable.mul(_lockingBps).div(MAX_BPS);
            uint256 beforeAmount = IERC20Upgradeable(xCitadel).balanceOf(
                address(this)
            );

            IxCitadel(xCitadel).deposit(lockingAmount);

            uint256 afterAmount = IERC20Upgradeable(xCitadel).balanceOf(
                address(this));

            xCitadelLocker.notifyRewardAmount(
                xCitadel,
                afterAmount.sub(beforeAmount));
        }

        if (_stakingBps != 0) {
            uint stakingAmount = mintable.mul(_stakingBps).div(MAX_BPS);
            IERC20Upgradeable(citadelToken).transfer(xCitadel, stakingAmount);
        }

        if (_fundingBps != 0) {
            uint fundingAmount = mintable.mul(_fundingBps).div(MAX_BPS);
            _transferToFundingPools(fundingAmount);
        }
    }

    // ===== Internal Functions =====

    // === Funding Pool Management ===
    function _transferToFundingPools(uint _citadelAmount) internal {
        require(fundingPools.length() > 0, "no funding pools");
        for (uint i = 0; i < fundingPools.length(); i++) {
            address pool = fundingPools.at(i);
            uint weight = fundingPoolWeights[pool];

            uint amonut = _citadelAmount.mul(weight).div(totalFundingPoolWeight);

            IERC20Upgradeable(citadelToken).safeTransfer(
                pool,
                amonut
            );
        }
    }

    function _setFundingPoolWeight(address _pool, uint _weight) internal {
        uint existingWeight = fundingPoolWeights[_pool];

        // Decreasing Weight
        if (existingWeight > _weight) {
            uint diff = existingWeight.sub(_weight);

            fundingPoolWeights[_pool] = _weight;
            totalFundingPoolWeight = totalFundingPoolWeight.sub(diff);
            emit FundingPoolWeightSet(_weight, false, diff, totalFundingPoolWeight);
        }

        // Increasing Weight
        else if (existingWeight < _weight) {
            uint diff = _weight.sub(existingWeight);
            
            fundingPoolWeights[_pool] = _weight;
            totalFundingPoolWeight = totalFundingPoolWeight.sub(diff);
            emit FundingPoolWeightSet(_weight, true, diff, totalFundingPoolWeight);
        }

        // If weight values are the same, no action is needed
    }

    function _removeFundingPool(address _pool) internal {
        require(fundingPools.remove(_pool), "funding pool does not exist for removal");
    }

    function _addFundingPool(address _pool) internal {
        require(fundingPools.add(_pool), "funding pool already exists");
    }


}
