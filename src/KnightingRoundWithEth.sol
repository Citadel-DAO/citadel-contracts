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

contract KnightingRoundWithEth is KnightingRound {
    using SafeERC20 for IERC20;

    function buyEth(uint8 _daoId, bytes32[] calldata _proof)
        external
        payable
        gacPausable
        returns (uint256 tokenOutAmount_)
    {
        uint256 _tokenInAmount = msg.value;
        require(saleStart <= block.timestamp, "KnightingRound: not started");
        require(
            block.timestamp < saleStart + saleDuration,
            "KnightingRound: already ended"
        );
        require(_tokenInAmount > 0, "_tokenInAmount should be > 0");
        require(
            totalTokenIn + _tokenInAmount <= tokenInLimit,
            "total amount exceeded"
        );

        if (address(guestlist) != address(0)) {
            require(guestlist.authorized(msg.sender, _proof), "not authorized");
        }

        uint256 boughtAmountTillNow = boughtAmounts[msg.sender];

        if (boughtAmountTillNow > 0) {
            require(
                _daoId == daoVotedFor[msg.sender],
                "can't vote for multiple daos"
            );
        } else {
            daoVotedFor[msg.sender] = _daoId;
        }

        tokenOutAmount_ = getAmountOut(_tokenInAmount);

        boughtAmounts[msg.sender] = boughtAmountTillNow + tokenOutAmount_;
        daoCommitments[_daoId] = daoCommitments[_daoId] + tokenOutAmount_;

        totalTokenIn = totalTokenIn + _tokenInAmount;
        totalTokenOutBought = totalTokenOutBought + tokenOutAmount_;

        payable(saleRecipient).transfer(_tokenInAmount);

        emit Sale(msg.sender, _daoId, _tokenInAmount, tokenOutAmount_);
    }
}
