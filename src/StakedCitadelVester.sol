// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./lib/GlobalAccessControlManaged.sol";

/**
 * @dev Time-locks tokens according to an unlock schedule.
 */

contract StakedCitadelVester is GlobalAccessControlManaged, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    struct VestingParams {
        uint256 unlockBegin;
        uint256 unlockEnd;
        uint256 lockedAmounts;
        uint256 claimedAmounts;
    }

    IERC20Upgradeable public vestingToken;
    address public vault;
    mapping(address => VestingParams) public vesting;

    uint256 public constant INITIAL_VESTING_DURATION = 86400 * 21; // 21 days of vesting
    uint256 public vestingDuration;

    event Vest(
        address indexed recipient,
        uint256 _amount,
        uint256 _unlockBegin,
        uint256 _unlockEnd
    );
    event Claimed(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    event SetVestingDuration(uint duration);

    function initialize(address _gac, address _vestingToken, address _vault) external initializer {
        require(_vestingToken != address(0), "Address zero invalid");

        __GlobalAccessControlManaged_init(_gac);
        __ReentrancyGuard_init();

        vestingDuration = INITIAL_VESTING_DURATION;

        vestingToken = IERC20Upgradeable(_vestingToken);
        vault = _vault;
    }
    
    /**
     * @notice modify vesting duration
     * @dev does not affect currently active vests, only future vests
     * @param _duration new vesting duration
    */
    function setVestingDuration(uint _duration) external onlyRole(CONTRACT_GOVERNANCE_ROLE) {
        vestingDuration = _duration;
        emit SetVestingDuration(_duration);
    }

    /**
     * @dev setup vesting for recipient.
     * @param recipient The account for which vesting will be setup.
     * @param _amount amount that will be vested
     * @param _unlockBegin The time at which unlocking of tokens will begin.
     */
    function vest(
        address recipient,
        uint256 _amount,
        uint256 _unlockBegin
    ) external {
        require(msg.sender == vault, "only xCTDL vault");
        require(_amount > 0);

        vesting[recipient].lockedAmounts = vesting[recipient].lockedAmounts.add(
            _amount
        );
        vesting[recipient].unlockBegin = _unlockBegin;
        vesting[recipient].unlockEnd = _unlockBegin.add(vestingDuration);

        emit Vest(
            recipient,
            vesting[recipient].lockedAmounts,
            _unlockBegin,
            vesting[recipient].unlockEnd
        );
    }

    /**
     * @notice Returns the maximum number of tokens currently claimable by `recipient`.
     * @param recipient The account to check the claimable balance of.
     * @return The number of tokens currently claimable.
     */
    function claimableBalance(address recipient) public view returns (uint256) {
        uint256 locked = vesting[recipient].lockedAmounts;
        uint256 claimed = vesting[recipient].claimedAmounts;
        if (block.timestamp >= vesting[recipient].unlockEnd) {
            return locked.sub(claimed);
        }
        return
            (
                (locked.mul(block.timestamp.sub(vesting[recipient].unlockBegin)))
                    .div(vestingDuration)
            ).sub(claimed);
    }

    /**
     * @notice Claims the caller's tokens that have been unlocked, sending them to `recipient`.
     * @param recipient The account to transfer unlocked tokens to.
     * @param amount The amount to transfer. If greater than the claimable amount, the maximum is transferred.
     */
    function claim(address recipient, uint256 amount) external {
        uint256 claimable = claimableBalance(msg.sender);
        if (amount > claimable) {
            amount = claimable;
        }
        if (amount != 0) {
            vesting[msg.sender].claimedAmounts = vesting[msg.sender]
                .claimedAmounts
                .add(amount);
            vestingToken.safeTransfer(recipient, amount);
            emit Claimed(msg.sender, recipient, amount);
        }
    }
}
