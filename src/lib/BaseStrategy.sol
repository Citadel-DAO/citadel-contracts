// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/badger/IVault.sol";

/*
    ===== Badger Base Strategy =====
    Common base class for all Sett strategies

    Changelog
    V1.1
    - Verify amount unrolled from strategy positions on withdraw() is within a threshold relative to the requested amount as a sanity check
    - Add version number which is displayed with baseStrategyVersion(). If a strategy does not implement this function, it can be assumed to be 1.0

    V1.2
    - Remove idle want handling from base withdraw() function. This should be handled as the strategy sees fit in _withdrawSome()

    V1.5
    - No controller as middleman. The Strategy directly interacts with the vault
    - withdrawToVault would withdraw all the funds from the strategy and move it into vault
    - strategy would take the actors from the vault it is connected to
        - SettAccessControl removed
    - fees calculation for autocompounding rewards moved to vault
    - autoCompoundRatio param added to keep a track in which ratio harvested rewards are being autocompounded
*/

abstract contract BaseStrategy is PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 public constant MAX_BPS = 10_000; // MAX_BPS in terms of BPS = 100%

    address public want; // Token used for deposits
    address public vault; // address of the vault the strategy is connected to
    uint256 public withdrawalMaxDeviationThreshold; // max allowed slippage when withdrawing

    /// @notice percentage of rewards converted to want
    /// @dev converting of rewards to want during harvest should take place in this ratio
    /// @dev change this ratio if rewards are converted in a different percentage
    /// value ranges from 0 to 10_000
    /// 0: keeping 100% harvest in reward tokens
    /// 10_000: converting all rewards tokens to want token
    uint256 public autoCompoundRatio; // NOTE: I believe this is unused

    // NOTE: You have to set autoCompoundRatio in the initializer of your strategy

    event SetWithdrawalMaxDeviationThreshold(uint256 newMaxDeviationThreshold);

    // Return value for harvest, tend and balanceOfRewards
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    /// @notice Initializes BaseStrategy. Can only be called once. 
    ///         Make sure to call it from the initializer of the derived strategy.
    /// @param _vault Address of the vault that the strategy reports to.
    function __BaseStrategy_init(address _vault) public onlyInitializing whenNotPaused {
        require(_vault != address(0), "Address 0");
        __Pausable_init();

        vault = _vault;

        withdrawalMaxDeviationThreshold = 50; // BPS
        // NOTE: See above
        autoCompoundRatio = 10_000;
    }

    // ===== Modifiers =====

    /// @notice Checks whether a call is from governance. 
    /// @dev For functions that only the governance should be able to call 
    ///      Most of the time setting setters, or to rescue/sweep funds
    function _onlyGovernance() internal view {
        require(msg.sender == governance(), "onlyGovernance");
    }

    /// @notice Checks whether a call is from strategist or governance. 
    /// @dev For functions that only known benign entities should call
    function _onlyGovernanceOrStrategist() internal view {
        require(msg.sender == strategist() || msg.sender == governance(), "onlyGovernanceOrStrategist");
    }

    /// @notice Checks whether a call is from keeper or governance. 
    /// @dev For functions that only known benign entities should call
    function _onlyAuthorizedActors() internal view {
        require(msg.sender == keeper() || msg.sender == governance(), "onlyAuthorizedActors");
    }

    /// @notice Checks whether a call is from the vault. 
    /// @dev For functions that only the vault should use
    function _onlyVault() internal view {
        require(msg.sender == vault, "onlyVault");
    }

    /// @notice Checks whether a call is from keeper, governance or the vault. 
    /// @dev Modifier used to check if the function is being called by a benign entity
    function _onlyAuthorizedActorsOrVault() internal view {
        require(msg.sender == keeper() || msg.sender == governance() || msg.sender == vault, "onlyAuthorizedActorsOrVault");
    }

    /// @notice Checks whether a call is from guardian or governance.
    /// @dev Modifier used exclusively for pausing
    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == guardian() || msg.sender == governance(), "onlyPausers");
    }

    /// ===== View Functions =====
    /// @notice Used to track the deployed version of BaseStrategy.
    /// @return Current version of the contract.
    function baseStrategyVersion() external pure returns (string memory) {
        return "1.5";
    }

    /// @notice Gives the balance of want held idle in the Strategy.
    /// @dev Public because used internally for accounting
    /// @return Balance of want held idle in the strategy.
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Gives the total balance of want managed by the strategy.
    ///         This includes all want deposited to active strategy positions as well as any idle want in the strategy.
    /// @return Total balance of want managed by the strategy.
    function balanceOf() external view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    /// @notice Tells whether the strategy is supposed to be tended.
    /// @dev This is usually a constant. The harvest keeper would only call `tend` if this is true.
    /// @return Boolean indicating whether strategy is supposed to be tended or not.
    function isTendable() external pure returns (bool) {
        return _isTendable();
    }

    function _isTendable() internal virtual pure returns (bool);

    /// @notice Checks whether a token is a protected token.
    ///         Protected tokens are managed by the strategy and can't be transferred/sweeped.
    /// @return Boolean indicating whether the token is a protected token.
    function isProtectedToken(address token) public view returns (bool) {
        require(token != address(0), "Address 0");

        address[] memory protectedTokens = getProtectedTokens();
        for (uint256 i = 0; i < protectedTokens.length; i++) {
            if (token == protectedTokens[i]) {
                return true;
            }
        }
        return false;
    }

    /// @notice Fetches the governance address from the vault.
    /// @return The governance address.
    function governance() public view returns (address) {
        return IVault(vault).governance();
    }

    /// @notice Fetches the strategist address from the vault.
    /// @return The strategist address.
    function strategist() public view returns (address) {
        return IVault(vault).strategist();
    }

    /// @notice Fetches the keeper address from the vault.
    /// @return The keeper address.
    function keeper() public view returns (address) {
        return IVault(vault).keeper();
    }

    /// @notice Fetches the guardian address from the vault.
    /// @return The guardian address.
    function guardian() public view returns (address) {
        return IVault(vault).guardian();
    }

    /// ===== Permissioned Actions: Governance =====
    
    /// @notice Sets the max withdrawal deviation (percentage loss) that is acceptable to the strategy.
    ///         This can only be called by governance.
    /// @dev This is used as a slippage check against the actual funds withdrawn from strategy positions.
    ///      See `withdraw`.
    function setWithdrawalMaxDeviationThreshold(uint256 _threshold) external {
        _onlyGovernance();
        require(_threshold <= MAX_BPS, "_threshold should be <= MAX_BPS");
        withdrawalMaxDeviationThreshold = _threshold;
        emit SetWithdrawalMaxDeviationThreshold(_threshold);
    }

    /// @notice Deposits any idle want in the strategy into positions.
    ///         This can be called by either the vault, keeper or governance.
    ///         Note that deposits don't work when the strategy is paused. 
    /// @dev See `deposit`.
    function earn() external whenNotPaused {
        deposit();
    }

    /// @notice Deposits any idle want in the strategy into positions.
    ///         This can be called by either the vault, keeper or governance.
    ///         Note that deposits don't work when the strategy is paused. 
    /// @dev Is basically the same as tend, except without custom code for it 
    function deposit() public whenNotPaused {
        _onlyAuthorizedActorsOrVault();
        uint256 _amount = IERC20Upgradeable(want).balanceOf(address(this));
        if (_amount > 0) {
            _deposit(_amount);
        }
    }

    // ===== Permissioned Actions: Vault =====

    /// @notice Withdraw all funds from the strategy to the vault, unrolling all positions.
    ///         This can only be called by the vault.
    /// @dev This can be called even when paused, and strategist can trigger this via the vault.
    ///      The idea is that this can allow recovery of funds back to the strategy faster.
    ///      The risk is that if _withdrawAll causes a loss, this can be triggered.
    ///      However the loss could only be triggered once (just like if governance called)
    ///      as pausing the strats would prevent earning again.
    function withdrawToVault() external {
        _onlyVault();

        _withdrawAll();

        uint256 balance = IERC20Upgradeable(want).balanceOf(address(this));
        _transferToVault(balance);
    }

    /// @notice Withdraw partial funds from the strategy to the vault, unrolling from strategy positions as necessary.
    ///         This can only be called by the vault.
    ///         Note that withdraws don't work when the strategy is paused. 
    /// @dev If the strategy fails to recover sufficient funds (defined by `withdrawalMaxDeviationThreshold`), 
    ///      the withdrawal would fail so that this unexpected behavior can be investigated.
    /// @param _amount Amount of funds required to be withdrawn.
    function withdraw(uint256 _amount) external whenNotPaused {
        _onlyVault();
        require(_amount != 0, "Amount 0");

        // Withdraw from strategy positions, typically taking from any idle want first.
        _withdrawSome(_amount);
        uint256 _postWithdraw = IERC20Upgradeable(want).balanceOf(address(this));

        // Sanity check: Ensure we were able to retrieve sufficient want from strategy positions
        // If we end up with less than the amount requested, make sure it does not deviate beyond a maximum threshold
        if (_postWithdraw < _amount) {
            uint256 diff = _diff(_amount, _postWithdraw);

            // Require that difference between expected and actual values is less than the deviation threshold percentage
            require(diff <= _amount.mul(withdrawalMaxDeviationThreshold).div(MAX_BPS), "withdraw-exceed-max-deviation-threshold");
        }

        // Return the amount actually withdrawn if less than amount requested
        uint256 _toWithdraw = MathUpgradeable.min(_postWithdraw, _amount);

        // Transfer remaining to Vault to handle withdrawal
        _transferToVault(_toWithdraw);
    }

    // Discussion: https://discord.com/channels/785315893960900629/837083557557305375
    /// @notice Sends balance of any extra token earned by the strategy (from airdrops, donations etc.) to the vault.
    ///         The `_token` should be different from any tokens managed by the strategy.
    ///         This can only be called by the vault.
    /// @dev This is a counterpart to `_processExtraToken`.
    ///      This is for tokens that the strategy didn't expect to receive. Instead of sweeping, we can directly
    ///      emit them via the badgerTree. This saves time while offering security guarantees.
    ///      No address(0) check because _onlyNotProtectedTokens does it.
    ///      This is not a rug vector as it can't use protected tokens.
    /// @param _token Address of the token to be emitted.
    function emitNonProtectedToken(address _token) external {
        _onlyVault();
        _onlyNotProtectedTokens(_token);
        IERC20Upgradeable(_token).safeTransfer(vault, IERC20Upgradeable(_token).balanceOf(address(this)));
        IVault(vault).reportAdditionalToken(_token);
    }

    /// @notice Withdraw the balance of a non-protected token to the vault.
    ///         This can only be called by the vault.
    /// @dev Should only be used in an emergency to sweep any asset.
    ///      This is the version that sends the assets to governance.
    ///      No address(0) check because _onlyNotProtectedTokens does it.
    /// @param _asset Address of the token to be withdrawn.
    function withdrawOther(address _asset) external {
        _onlyVault();
        _onlyNotProtectedTokens(_asset);
        IERC20Upgradeable(_asset).safeTransfer(vault, IERC20Upgradeable(_asset).balanceOf(address(this)));
    }

    /// ===== Permissioned Actions: Authorized Contract Pausers =====

    /// @notice Pauses the strategy.
    ///         This can be called by either guardian or governance.
    /// @dev Check the `onlyWhenPaused` modifier for functionality that is blocked when pausing
    function pause() external {
        _onlyAuthorizedPausers();
        _pause();
    }

    /// @notice Unpauses the strategy.
    ///         This can only be called by governance (usually a multisig behind a timelock).
    function unpause() external {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Helper Functions =====

    /// @notice Transfers `_amount` of want to the vault.
    /// @dev Strategy should have idle funds >= `_amount`.
    /// @param _amount Amount of want to be transferred to the vault.
    function _transferToVault(uint256 _amount) internal {
        if (_amount > 0) {
            IERC20Upgradeable(want).safeTransfer(vault, _amount);
        }
    }

    /// @notice Report an harvest to the vault.
    /// @param _harvestedAmount Amount of want token autocompounded during harvest.
    function _reportToVault(
        uint256 _harvestedAmount
    ) internal {
        IVault(vault).reportHarvest(_harvestedAmount);
    }

    /// @notice Sends balance of an additional token (eg. reward token) earned by the strategy to the vault.
    ///         This should usually be called exclusively on protectedTokens.
    ///         Calls `Vault.reportAdditionalToken` to process fees and forward amount to badgerTree to be emitted.
    /// @dev This is how you emit tokens in V1.5
    ///      After calling this function, the tokens are gone, sent to fee receivers and badgerTree
    ///      This is a rug vector as it allows to move funds to the tree
    ///      For this reason, it is recommended to verify the tree is the badgerTree from the registry
    ///      and also check for this to be used exclusively on harvest, exclusively on protectedTokens.
    /// @param _token Address of the token to be emitted.
    /// @param _amount Amount of token to transfer to vault.
    function _processExtraToken(address _token, uint256 _amount) internal {
        require(_token != want, "Not want, use _reportToVault");
        require(_token != address(0), "Address 0");
        require(_amount != 0, "Amount 0");

        IERC20Upgradeable(_token).safeTransfer(vault, _amount);
        IVault(vault).reportAdditionalToken(_token);
    }

    /// @notice Utility function to diff two numbers, expects higher value in first position
    function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "a should be >= b");
        return a.sub(b);
    }

    // ===== Abstract Functions: To be implemented by specific Strategies =====

    /// @dev Internal deposit logic to be implemented by a derived strategy.
    /// @param _want Amount of want token to be deposited into the strategy.
    function _deposit(uint256 _want) internal virtual;

    /// @notice Checks if a token is not used in yield process.
    /// @param _asset Address of token.
    function _onlyNotProtectedTokens(address _asset) internal view {
        require(!isProtectedToken(_asset), "_onlyNotProtectedTokens");
    }

    /// @notice Gives the list of protected tokens.
    /// @return Array of protected tokens.
    function getProtectedTokens() public view virtual returns (address[] memory);

    /// @dev Internal logic for strategy migration. Should exit positions as efficiently as possible.
    function _withdrawAll() internal virtual;

    /// @dev Internal logic for partial withdrawals. Should exit positions as efficiently as possible.
    ///      Should ideally use idle want in the strategy before attempting to exit strategy positions.
    /// @param _amount Amount of want token to be withdrawn from the strategy.
    /// @return Withdrawn amount from the strategy.
    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    /// @notice Realize returns from strategy positions.
    ///         This can only be called by keeper or governance.
    ///         Note that harvests don't work when the strategy is paused. 
    /// @dev Returns can be reinvested into positions, or distributed in another fashion.
    /// @return harvested An array of `TokenAmount` containing the address and amount harvested for each token.
    function harvest() external whenNotPaused returns (TokenAmount[] memory harvested) {
        _onlyAuthorizedActors();
        return _harvest();
    }

    /// @dev Virtual function that should be overridden with the logic for harvest. 
    ///      Should report any want or non-want gains to the vault.
    ///      Also see `harvest`.
    function _harvest() internal virtual returns (TokenAmount[] memory harvested);

    /// @notice Tend strategy positions as needed to maximize returns.
    ///         This can only be called by keeper or governance.
    ///         Note that tend doesn't work when the strategy is paused. 
    /// @dev Is only called by the keeper when `isTendable` is true.
    /// @return tended An array of `TokenAmount` containing the address and amount tended for each token.
    function tend() external whenNotPaused returns (TokenAmount[] memory tended) {
        _onlyAuthorizedActors();

        return _tend();
    }

    /// @dev Virtual function that should be overridden with the logic for tending. 
    ///      Also see `tend`.
    function _tend() internal virtual returns (TokenAmount[] memory tended);


    /// @notice Fetches the name of the strategy.
    /// @dev Should be user-friendly and easy to read.
    /// @return Name of the strategy.
    function getName() external pure virtual returns (string memory);

    /// @notice Gives the balance of want held in strategy positions.
    /// @return Balance of want held in strategy positions.
    function balanceOfPool() public view virtual returns (uint256);

    /// @notice Gives the total amount of pending rewards accrued for each token.
    /// @dev Should take into account all reward tokens.
    /// @return rewards An array of `TokenAmount` containing the address and amount of each reward token.
    function balanceOfRewards() external view virtual returns (TokenAmount[] memory rewards);

    uint256[49] private __gap;
}