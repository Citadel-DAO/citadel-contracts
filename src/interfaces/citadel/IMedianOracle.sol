/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IMedianOracle {

    struct Report {
        uint256 timestamp;
        uint256 payload;
    }

    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);
    event ReportTimestampOutOfRange(address provider);
    event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);

    function reportExpirationTimeSec() external view returns(uint256);
    function getData() external view returns (uint256, bool);
    function providerReports(address provider) external view returns (Report[2] calldata);

    function pushReport(uint256 payload) external;
    
}
