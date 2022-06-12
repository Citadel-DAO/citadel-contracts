// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Funding.sol";
/**
 * @notice Sells a token at a predetermined price to whitelisted buyers.
 * TODO: Better revert strings
 */
contract FundingWithEth is Funding {

    /// ==========================
    /// ===== Public actions =====
    /// ==========================

    /**
     * @notice Exchange `msg.value` of Ether for `citadel`
     * @param _minCitadelOut Minimum amount of `citadel` to receive
     * @return citadelAmount_ Amount of `xCitadel` bought
     */
    function depositEth(uint256 _minCitadelOut)
        external
        payable
        onlyWhenPriceNotFlagged
        gacPausable
        nonReentrant
        returns (uint256 citadelAmount_)
    {
        uint256 _assetAmountIn = msg.value;
        require(_assetAmountIn > 0, "_assetAmountIn must not be 0");
        require(
            funding.assetCumulativeFunded + _assetAmountIn <= funding.assetCap,
            "asset funding cap exceeded"
        );
        funding.assetCumulativeFunded =
            funding.assetCumulativeFunded +
            _assetAmountIn;
        // Take in asset from user
        citadelAmount_ = getAmountOut(_assetAmountIn);
        require(citadelAmount_ >= _minCitadelOut, "minCitadelOut");

        payable(saleRecipient).transfer(_assetAmountIn);

        // Deposit xCitadel and send to user
        // TODO: Check gas costs. How does this relate to market buying if you do want to deposit to xCTDL?
        xCitadel.depositFor(msg.sender, citadelAmount_);

        emit Deposit(msg.sender, _assetAmountIn, citadelAmount_);
    }

    function deposit(uint256 _assetAmountIn, uint256 _minCitadelOut)
        external
        override
        onlyWhenPriceNotFlagged
        gacPausable
        nonReentrant
        returns (uint256 citadelAmount_)
    {
        revert("FundingWithEth: use depositEth");
    }

}
