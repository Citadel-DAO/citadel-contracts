// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {KnightingRound} from "./KnightingRound.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

interface WETH {
    function deposit() external payable;

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}

/// @notice Knighting Round Contract to buy citadel with eth
contract KnightingRoundWithEth is KnightingRound {
    using SafeERC20 for IERC20;

    /// @notice function to buy citadel with eth
    /// @param _daoId the dao id user wants to vote
    /// @return tokenOutAmount_ the amount of citadel user will get
    function buyEth(uint8 _daoId, bytes32[] calldata _proof)
        external
        payable
        gacPausable
        returns (uint256 tokenOutAmount_)
    {
        WETH weth = WETH(address(tokenIn));
        weth.deposit{value: msg.value}();
        IERC20(address(tokenIn)).safeTransfer(msg.sender, msg.value);
        tokenOutAmount_ = super.buy(msg.value, _daoId, _proof);
    }
}
