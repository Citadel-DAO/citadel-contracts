// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./Funding.sol";
import "./lib/GlobalAccessControlManaged.sol";

contract FundingRegistry is Initializable, GlobalAccessControlManaged {
    // ===== Libraries  ====
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    address public proxyAdmin;

    event FundingAdded(address fundingAddress);

    struct FundingAsset {
        address asset;
        address citadelPerAssetOracle;
        uint256 assetCap;
    }

    struct FundingData {
        address fundingAddress;
        uint256 citadelPerAsset;
        uint256 minCitadelPerAsset;
        uint256 maxCitadelPerAsset;
        address asset;
        bool citadelPriceFlag;
        uint256 assetDecimalsNormalizationValue;
        address citadelPerAssetOracle;
        address saleRecipient;
        Funding.FundingParams funding;
        uint256 remainingFundable;
    }

    address public gacAddress;
    address public citadel;
    address public xCitadel;
    address public saleRecipient;

    address public fundingImplementation;

    EnumerableSet.AddressSet private fundings;

    function initialize(
        address _fundingImplementation,
        bytes4 _selector,
        address _proxyAdmin,
        address _gac,
        address _citadel,
        address _xCitadel,
        address _saleRecipient,
        FundingAsset[] calldata _fundingAssets
    ) public initializer {
        __GlobalAccessControlManaged_init(_gac);

        gacAddress = _gac;
        citadel = _citadel;
        xCitadel = _xCitadel;
        saleRecipient = _saleRecipient;

        proxyAdmin = _proxyAdmin;

        fundingImplementation = address(_fundingImplementation);

        /// for other
        for (uint256 i = 0; i < _fundingAssets.length; i++) {
            addRound(_fundingAssets[i], _selector);
        }
    }

    function addRound(FundingAsset calldata _fundingAsset, bytes4 _selector)
        public
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        TransparentUpgradeableProxy currFunding = new TransparentUpgradeableProxy(
                address(fundingImplementation),
                address(proxyAdmin),
                abi.encodeWithSelector(
                    _selector,
                    gacAddress,
                    citadel,
                    _fundingAsset.asset,
                    xCitadel,
                    saleRecipient,
                    _fundingAsset.citadelPerAssetOracle,
                    _fundingAsset.assetCap
                )
            );
        emit FundingAdded(address(currFunding));
        fundings.add(address(currFunding));
    }

    function getFundingData(address _fundingAddress)
        public
        view
        returns (FundingData memory fundingData)
    {
        Funding funding = Funding(_fundingAddress);
        fundingData.fundingAddress = address(funding);
        fundingData.citadelPerAsset = funding.citadelPerAsset();
        fundingData.minCitadelPerAsset = funding.minCitadelPerAsset();
        fundingData.maxCitadelPerAsset = funding.maxCitadelPerAsset();
        fundingData.asset = address(funding.asset());
        fundingData.citadelPriceFlag = funding.citadelPriceFlag();
        fundingData.assetDecimalsNormalizationValue = funding
            .assetDecimalsNormalizationValue();
        fundingData.citadelPerAssetOracle = funding.citadelPerAssetOracle();
        fundingData.saleRecipient = funding.saleRecipient();
        fundingData.funding = Funding.FundingParams(
            funding.getFundingParams().discount,
            funding.getFundingParams().minDiscount,
            funding.getFundingParams().maxDiscount,
            funding.getFundingParams().discountManager,
            funding.getFundingParams().assetCumulativeFunded,
            funding.getFundingParams().assetCap
        );
        fundingData.remainingFundable = funding.getRemainingFundable();
    }

    function getAllFundings() public view returns (address[] memory) {
        address[] memory fundingsList = new address[](fundings.length());
        for (uint256 i = 0; i < fundings.length(); i++) {
            fundingsList[i] = fundings.at(i);
        }
        return fundingsList;
    }

    function getAllFundingsData() public view returns (FundingData[] memory) {
        FundingData[] memory fundingsData = new FundingData[](
            fundings.length()
        );
        for (uint256 i = 0; i < fundings.length(); i++) {
            fundingsData[i] = getFundingData(fundings.at(i));
        }
        return fundingsData;
    }
}
