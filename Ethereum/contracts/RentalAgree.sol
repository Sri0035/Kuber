// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract AgreementMaker{
    address payable[] public deployedAgreementContracts;
    function createAgreementContract(address landlord, address tenant, uint securityDeposit, uint rentAmount, uint leaseDuration) public payable  {
        address newAgreementContract = address(new RentalAgreement(landlord, tenant, securityDeposit, rentAmount, leaseDuration));
        deployedAgreementContracts.push(payable(newAgreementContract));
    }

    function getDeployedAgreements() public  view returns (address payable[] memory){
        return deployedAgreementContracts;
    }
}



contract RentalAgreement {
    address public landlord;
    address public tenant;
    address public broker;
    uint public securityDeposit;
    uint public rentAmount;
    uint public leaseDuration; 
    uint public startDate;
    uint public endDate;
    bool public isLeaseActive;
    bool public isAutoRenewalEnabled;
    bool public isDispute;

    event AgreementInitialized(address indexed _landlord, address indexed _tenant, uint _securityDeposit, uint _rentAmount, uint _leaseDuration, uint _startDate, uint _endDate);
    event RentPaid(uint _amount);
    event LeaseRenewed(uint _newEndDate);
    event DisputeRaised();

    constructor(address _landlord, address _tenant, uint _securityDeposit, uint _rentAmount, uint _leaseDuration) payable  {
        require(msg.value == securityDeposit, "Security deposit not found");
        broker = msg.sender;
        landlord = _landlord;
        tenant = _tenant;
        securityDeposit = _securityDeposit;
        rentAmount = _rentAmount;
        leaseDuration = _leaseDuration;
        startDate = block.timestamp;
        endDate = startDate + (_leaseDuration * 30 days); // assuming 30 days per month
        isLeaseActive = true;
        isAutoRenewalEnabled = true;
        emit AgreementInitialized(landlord, tenant, securityDeposit, rentAmount, leaseDuration, startDate, endDate);
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord can call this function");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only tenant can call this function");
        _;
    }

    modifier onlyBroker() {
        require(msg.sender == broker, "only broker can call this function");
        _;
    }

    

    function payRent() public payable onlyTenant {
        require(msg.value == rentAmount, "Incorrect rent amount sent");
        require(block.timestamp <= endDate, "Lease has expired");
        (bool sent, ) = landlord.call{value: msg.value}("");
        require(sent, "Failed to send rent to landlord");
        emit RentPaid(msg.value);
    }

    function renewLease() public onlyLandlord {
        require(isAutoRenewalEnabled, "Auto renewal is not enabled");
        endDate += (leaseDuration * 30 days); // assuming 30 days per month
        emit LeaseRenewed(endDate);
    }

    function enableAutoRenewal() public onlyLandlord {
        isAutoRenewalEnabled = true;
    }

    function disableAutoRenewal() public onlyLandlord {
        isAutoRenewalEnabled = false;
    }

    function raiseDispute() public onlyTenant {
        isDispute = true;
        emit DisputeRaised();
    }

    function resolveDispute() public onlyBroker {
        require(isDispute, "No dispute raised");
        isDispute = false;
    }

    function withdrawSecurityDeposit() public onlyTenant {
        require(!isLeaseActive, "Lease is still active");
        (bool sent, ) = payable(tenant).call{value: securityDeposit}("");
        require(sent, "Failed to send security deposit to tenant");
    }

    function terminateLease() public onlyBroker {
        isLeaseActive = false;
    }
}
