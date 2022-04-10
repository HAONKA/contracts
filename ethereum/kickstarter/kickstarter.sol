pragma solidity ^0.8.13;

contract CampaignFactory{
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        address newCampaign = address(new Campaign(minimum, msg.sender));
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns(address[] memory){
        return deployedCampaigns;
    }
}

contract Campaign {

    struct Request{
        string description;                 //What to spend money
        uint value;                         //How much money need
        address payable recipient;          //Money will be sent to
        bool complete;                      //Request completed or not
        uint approvalCount;                 //Number of people who vote 'Yes' for expense
        mapping(address => bool) approvals; //Contributer vote list for the request
    }
   
    //Manager who creates the project to collect contributions
    address public manager;
    //Contributers have to deposit at least -minimumContribution- in order to contribute a project
    uint public minimumContribution;
    //Mapped list of contributers with their vote
    mapping(address => bool) public approvers;
    //Number of contributers
    uint public approversCount;
    address payable contributer;

    Request[] public requests;
    uint numRequests;
    mapping (uint => Request) requestsIndexMap;

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    //Project owner who creates Campaign decides the -minimumContribution- value by entering as a parameter
    constructor(uint minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }
    
    function contribute() public payable {
        //Contribute function does not work if the contrbution value lower than the -minimumContribution-
        require(msg.value > minimumContribution);
        contributer = payable(msg.sender);

        approvers[contributer] = false;
    }

    //Project owner use this function to create a request to send money to 3rd party seller
    function createRequest(string memory description, uint value, address payable recipient) public restricted{
        Request storage newRequest = requests[numRequests++];
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];
        
        require(request.approvalCount > (approversCount / 2));
        require(!requests[index].complete);

        request.recipient.transfer(request.value);
        requests[index].complete = true;
    }
}