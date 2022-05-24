// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import {BaseStrategy} from "./lib/BaseStrategy.sol";

contract BrickedStrategy is BaseStrategy {
    /// @dev Initialize the Strategy with security settings as well as tokens
    /// @notice Proxies will set any non constant variable you declare as default value
    /// @dev add any extra changeable variable at end of initializer as shown
    function initialize(address _vault, address _want) public initializer {
        require(_vault != address(0), "address 0 invalid");
        require(_want != address(0), "address 0 invalid");
        __BaseStrategy_init(_vault);
        want = _want;
    }

    /// @dev Return the name of the strategy
    function getName() external pure override returns (string memory) {
        return "BrickedStrategy";
    }

    /// @dev Return a list of protected tokens
    /// @notice It's very important all tokens that are meant to be in the strategy to be marked as protected
    /// @notice this provides security guarantees to the depositors they can't be sweeped away
    function getProtectedTokens()
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](1);
        protectedTokens[0] = want;
        return protectedTokens;
    }

    /// @dev Deposit `_amount` of want, investing it to earn yield
    // solhint-disable-next-line no-empty-blocks
    function _deposit(uint256 _amount) internal override {
        // No-op
    }

    /// @dev Withdraw all funds, this is used for migrations, most of the time for emergency reasons
    // solhint-disable-next-line no-empty-blocks
    function _withdrawAll() internal override {
        // No-op
    }

    /// @dev Withdraw `_amount` of want, so that it can be sent to the vault / depositor
    /// @notice just unlock the funds and return the amount you could unlock
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        // No-op
        return _amount;
    }

    /// @dev Does this function require `tend` to be called?
    function _isTendable() internal pure override returns (bool) {
        return false; // Change to true if the strategy should be tended
    }

    function _harvest()
        internal
        override
        returns (TokenAmount[] memory harvested)
    {
        // No-op as we don't do anything with funds

        // Nothing harvested, we have 2 tokens, return both 0s
        harvested = new TokenAmount[](1);
        harvested[0] = TokenAmount(want, 0);

        // keep this to get paid!
        _reportToVault(0);

        return harvested;
    }

    // Example tend is a no-op which returns the values, could also just revert
    function _tend() internal override returns (TokenAmount[] memory tended) {
        // Nothing tended
        tended = new TokenAmount[](1);
        tended[0] = TokenAmount(want, 0);
        return tended;
    }

    /// @dev Return the balance (in want) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // No pool
        return 0;
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards()
        external
        view
        override
        returns (TokenAmount[] memory rewards)
    {
        // Rewards are 0
        rewards = new TokenAmount[](1);
        rewards[0] = TokenAmount(want, 0);
        return rewards;
    }
}
