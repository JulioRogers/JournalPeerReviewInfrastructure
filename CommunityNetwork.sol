// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./JPRI.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Network{
// ---------------------------------------- TOKEN ------------------------------------------------
    ERC20 token;
    address contractaddress;

    constructor () {
        token = new ERC20("THESIS","THS");
        contractaddress = address(this);
    }


    function TokenPrice(uint _numTokens) internal pure returns (uint){
        return _numTokens*(1 ether);
    }

    function BuyTokens(uint _numTokens) public payable {
        uint cost = TokenPrice(_numTokens);
        require (msg.value >= cost, "Buy less Tokens or pay with more Ethers.");
        payable(msg.sender).transfer(msg.value - cost);
        require (_numTokens <= TokensAvailable(), "Buy a suitable number of Tokens.");
        token.transfer(msg.sender, _numTokens);
    }

    function TokensAvailable() public view returns (uint) {
        return token.balanceOf(contractaddress);
    }

    //--- Token Balance
    function OwnTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }
/*
    //--- Return tokens 
    function ReturnTokens(uint _numTokens) public payable {
        require(_numTokens > 0 , "You need to return a positive number of tokens.");
        require (_numTokens <= OwnTokens(), "You don't have the tokens you want to return.");
        token.transf_network(msg.sender, address(this), _numTokens);
        payable(msg.sender).transfer(TokenPrice(_numTokens));
    }
*/
// ---------------------------------------- USERS ------------------------------------------------
// Structures and Variables
    struct user {
        string _FullName;
        string _Email;
        string _University;
        bool _RevisorRol;
        string [] _Journals;
        uint [] _Manuscripts;
        uint [] _Articles;
        uint [] _Reviews;}

    mapping (address=> user) public _Users;



// UserRegister(Pass)
    ////event UserRegistered(address userAddress, string fullname);

    function UserRegister(string memory _fullname, string memory _email, string memory _university,
    bool _revisorrol) public {
    
        require(bytes(_Users[msg.sender]._FullName).length == 0, "User is already registered");
        require(bytes(_fullname).length > 0, "Full name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        require(bytes(_university).length > 0, "Email cannot be empty");
        require(_revisorrol == false || _revisorrol == true, "Revisor role cannot be blank");

        string [] memory _journals;
        uint [] memory _manuscripts;
        uint [] memory _articles;
        uint [] memory _reviews;

	    user memory _NewUser = user(_fullname, _email, _university, _revisorrol, 
        _journals, _manuscripts, _articles, _reviews);
	    _Users[msg.sender]=_NewUser;
    
        ////emit UserRegistered(msg.sender, _fullname);
    }


// Update data(pass)
    ////event UserUpdated(address userAddress, string fullname);

    function UpdateData(string memory _email, string memory _university, bool _revisorrol) public {

        require(bytes(_Users[msg.sender]._FullName).length > 0, "User does not exit");


        if(bytes(_email).length > 0){_Users[msg.sender]._Email = _email;}
        if(bytes(_university).length > 0){_Users[msg.sender]._University = _university;}
        if(_revisorrol == true || _revisorrol == false){_Users[msg.sender]._RevisorRol = _revisorrol;}

        ////emit UserUpdated(msg.sender, _Users[msg.sender]._FullName);
    }

    function EnrolInternal(address sender, string memory _journal) external {
        _Users[sender]._Journals.push(_journal);
    }

// ---------------------------------------- JOURNALS -------------------------------------------------

// Structures and Variables

    struct journalrequest { address _Requester;
                        string _Name;
                        string _AboutLink;
                        uint _Time;
                        string _State;
                        uint _UpVotes;
                        uint _DownVotes;}

    mapping (uint=> journalrequest) public _JournalRequests;


    struct journal { string _Name;
                     string _FGSP;
                     uint _N1;
                     string _SGSP;
                     uint _N2;
                     string _IP;
                     uint _Cost;}

    mapping (address=> journal) public _Journals;


// RequestJournalCreation(pass)

    // Functions for RequestID
    uint private _RequestId = 0;

    //FUNCTION 
    
    event JournalCreationRequest(address userAddress, string fullname);


    function RequestJournalCreation(string memory _name, string memory _aboutlink) public returns(uint){
        require(bytes(_Users[msg.sender]._FullName).length > 0, "You need to be registered to do the request");

        journalrequest memory _NewJournalRequest = journalrequest(msg.sender, _name, _aboutlink, 
            block.timestamp, "in progress", 0, 0);
        uint _idrequest = _RequestId;
        _RequestId += 1;
        _JournalRequests[_idrequest] = _NewJournalRequest;

        emit JournalCreationRequest(msg.sender, _name);

        return  _idrequest;

    }

// SeeRequests(no-pass)

    function SeeRequests() private{
	//return _JournalRequests;
    }

// VoteRequest (pass)

    mapping (uint => mapping (address => bool)) public _HasVoted;

    event VotingTimeOver(string message);

    //FUNCTION
    function  VoteRequest(uint _id, string memory _vote) public {

        require(bytes(_Users[msg.sender]._FullName).length > 0, "You need to be registered to vote");
        require(!_HasVoted[_id][msg.sender], "You have already voted.");

        //604800 == 1week
	    if (block.timestamp - _JournalRequests[_id]._Time < 60){
		    if(keccak256(abi.encodePacked(_vote)) == keccak256("in favor")){
			    _JournalRequests[_id]._UpVotes+=1;
            }else if (keccak256(abi.encodePacked(_vote)) == keccak256("against")){
	            _JournalRequests[_id]._DownVotes+=1;
        }
        _HasVoted[_id][msg.sender] = true;
        }else{
            emit VotingTimeOver("the time to vote is over.");}}



// SeeRequestStatus(pass)
    function SeeRequestStatus(uint _id) public returns(string memory){

        require(bytes(_Users[msg.sender]._FullName).length > 0, "You need to be registered to see");

	    if (block.timestamp - _JournalRequests[_id]._Time >= 60 &&
        keccak256(abi.encodePacked(_JournalRequests[_id]._State)) == keccak256(abi.encodePacked("in progress"))){
            if (_JournalRequests[_id]._UpVotes > _JournalRequests[_id]._DownVotes){
                _JournalRequests[_id]._State = "accepted";
            } else{
                _JournalRequests[_id]._State = "rejected";}}
	    return _JournalRequests[_id]._State;
    }

//CreateJournal(pass)
    function CreateJournal(uint _id, string memory _name, string memory _fgsp, uint _n1, 
    string memory _sgsp, uint _n2, string memory _ip, uint _cost) public returns(address){

        require(keccak256(abi.encodePacked(_JournalRequests[_id]._State)) == keccak256(abi.encodePacked("accepted")),
        "Your Journal request has not been accepted yet");
        require(keccak256(abi.encodePacked(_JournalRequests[_id]._Requester)) == keccak256(abi.encodePacked(msg.sender)),
        "You are not the journal requester");

	    journal memory _NewJournal = journal(_name, _fgsp, _n1, _sgsp, _n2, _ip,  _cost);
        address _JournalAddress = address (new JPRI(_name, _fgsp, _n1, _sgsp, _n2, _ip,  _cost, address(token), address(this), msg.sender));
        _Journals[_JournalAddress] = _NewJournal;

	    return _JournalAddress;
        }

//SeeJournals(No pass)
    function TokenAddress() public view returns(address){
	return address(token);
    }

    function ContractAddress() public view returns(address){
	return address(this);
    }

}