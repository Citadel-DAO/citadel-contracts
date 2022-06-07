// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

abstract contract ChainlinkUtils {
    /// =========================
    /// ===== Internal view =====
    /// =========================

    function safeLatestAnswer(IAggregatorV3Interface _priceFeed)
        internal
        view
        returns (
            uint256 answer_,
            uint256 updateTime_,
            bool valid_
        )
    {
        (
            uint256 roundId,
            int256 price,
            ,
            uint256 updateTime,
            uint256 answeredInRound
        ) = _priceFeed.latestRoundData();

        updateTime_ = updateTime;

        // TODO: Check if this is the correct way to check if the price is valid
        valid_ = price > 0 && updateTime_ > 0 && answeredInRound >= roundId;

        answer_ = uint256(price);
    }
}
