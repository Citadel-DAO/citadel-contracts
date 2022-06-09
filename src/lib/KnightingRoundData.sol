// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "../KnightingRound.sol";

library KnightingRoundData {
    struct RoundData {
        address roundAddress;
        address tokenOut;
        address tokenIn;
        uint256 saleStart;
        uint256 saleDuration;
        address saleRecipient;
        bool finalized;
        uint256 tokenOutPerTokenIn;
        uint256 totalTokenIn;
        uint256 totalTokenOutBought;
        uint256 totalTokenOutClaimed;
        uint256 tokenInLimit;
        uint256 tokenInNormalizationValue;
        address guestlist;
        bool isEth;
    }

    struct InitParam {
        address _tokenIn;
        uint256 _tokenInLimit;
        uint256 _tokenOutPerTokenIn;
    }

    function getRoundData(
        address _roundAddress,
        address _knightingRoundsWithEth
    ) public view returns (KnightingRoundData.RoundData memory roundData) {
        KnightingRound targetRound = KnightingRound(_roundAddress);
        roundData.roundAddress = _roundAddress;
        roundData.tokenOut = address(targetRound.tokenOut());
        roundData.tokenIn = address(targetRound.tokenIn());
        roundData.saleStart = targetRound.saleStart();
        roundData.saleDuration = targetRound.saleDuration();
        roundData.saleRecipient = targetRound.saleRecipient();
        roundData.finalized = targetRound.finalized();
        roundData.tokenOutPerTokenIn = targetRound.tokenOutPerTokenIn();
        roundData.totalTokenIn = targetRound.totalTokenIn();
        roundData.totalTokenOutBought = targetRound.totalTokenOutBought();
        roundData.totalTokenOutClaimed = targetRound.totalTokenOutClaimed();
        roundData.tokenInLimit = targetRound.tokenInLimit();
        roundData.tokenInNormalizationValue = targetRound
            .tokenInNormalizationValue();
        roundData.guestlist = address(targetRound.guestlist());
        if (_roundAddress == _knightingRoundsWithEth) {
            roundData.isEth = true;
        } else {
            roundData.isEth = false;
        }
    }

    function getAllRoundsData(address[] memory _allRounds)
        public
        view
        returns (RoundData[] memory)
    {
        RoundData[] memory roundsData = new RoundData[](_allRounds.length);
        for (uint256 i = 0; i < _allRounds.length; i++) {
            roundsData[i] = getRoundData(
                _allRounds[i],
                _allRounds[_allRounds.length - 1]
            );
        }
        return roundsData;
    }
}
