// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./CommunityNetwork.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


    /* --------------------------------------------------------------------------------------------------------------- 

       ---------------------------------------- CONTRATO: REVISTAS --------------------------------------------------- 
       --------------------------------------------------------------------------------------------------------------- */


contract JPRI{

// Constructor
    Network private  Community;
    ERC20 private token;
    string private name;
    string private firstGSP;
    uint256 private firstGSPNumber;
    string private secondGSP;
    uint256 private secondGSPNumber;
    string private ip;
    uint256 private submissionfee;
    address private owner;
    
    constructor(string memory _name, string memory _fgsp, uint256 _n1, 
    string memory _sgsp, uint256 _n2, string memory _ip, uint256 _cost, 
    address _token, address _community, address _owner){
        name = _name;
        firstGSP = _fgsp;
        firstGSPNumber = _n1;
        secondGSP = _sgsp;
        secondGSPNumber = _n2;
        ip = _ip;
        submissionfee = _cost;
        token = ERC20(_token);
        Community = Network(_community);
        owner = _owner;
    }


//--------------------PREVIO---------------------------

 // EnrolFunction
    address[] Reviewers;
    mapping (address=>uint) ReviewersWorking;

    function Enrol(bool _Reviewer) public {
        Community.EnrolInternal(msg.sender, name);
        if (_Reviewer==true) {Reviewers.push(msg.sender);}
    }


 // UpdateReviewerState

    function removeItem(address[] storage array, address itemaddress) internal {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == itemaddress) {
                array[i] =array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    function UpdateReviewerState(bool _Reviewer) public {
        if (_Reviewer==true) {Reviewers.push(msg.sender);}
        else{removeItem(Reviewers, msg.sender);}
    }


 // Suscribers

    struct Suscriber {
        address[] manuscripts; //se guarda el address del manuscript.
        address[] reviewsinprocess; //se guarda el address del manuscript.
        address[] articles; //se guarda el address del manuscript aprobado.
        address[] reviews; //se guarda el address del manuscript.
    }

    mapping (address => Suscriber) Suscribers;

    enum ManuscriptDecision {
    InProcess,
    Reject,
    Accept,
    ChangesRequired
}
 // Manuscripts
    struct ManuscriptProcess {
        address primaryauthor;
        address authors;
        string title;
        string filelink;
        bool paid;

        address[] fgreviewers; //fg: first group
        ManuscriptDecision[] fgdecision;
        string[] fgdecisionlink;

        address[] sgreviewers; //sg: second group
        ManuscriptDecision[] sgdecision;
        string[] sgdecisionlink;

        ManuscriptDecision state;
        uint nstate;
        bytes32 previousreviewaddress; // un hash de las primeras 4 y esta de aca
    }

    mapping (bytes32 => ManuscriptProcess) ManuscriptProcesses;

    //bytes32 Hash_Id_Manuscript = keccak256(abi.encodePacked(_primaryauthor, _title, _filelink, previousreviewaddress));

 // Reviewers

     // Mapping to store reviewer selections
    mapping(address => bytes32[]) public reviewerSelectedManuscripts;

    function _addReviewerToSelectedManuscripts(address reviewer, bytes32 manuscriptHash) private {
        reviewerSelectedManuscripts[reviewer].push(manuscriptHash);
    }

 // RandomSelection()
    function RandomSelection(address[] storage array, uint amount, bytes32 hash_Id_Manuscript) internal{
        require(Reviewers.length > amount, "Not enough reviewers");
        for (uint i=0;i<amount;i++){
            uint random = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % Reviewers.length);
            array.push(Reviewers[random]);
            _addReviewerToSelectedManuscripts(Reviewers[random], hash_Id_Manuscript);
        }

    }


 //DesignationSelection()
    address[] Editors;
    mapping(address=> bool) IsEditor;

    bytes32[] ReviewOpeningsForAssign;

    function createReviewOpeningsForAssign(bytes32 idManuscriptProcess) private{
        ReviewOpeningsForAssign.push(idManuscriptProcess);
    }

    function addEditor(address newEditor) public {
        require(msg.sender == owner, "Only the contract owner can add editors");
        Editors.push(newEditor);
        IsEditor[newEditor]=true;
    }

    //function DesignationSelection(){}
    function addReviewers(address[] storage newReviewers, bytes32 hash_Id_Manuscript) internal {
    require(IsEditor[msg.sender], "Only editors can add reviewers");
    require(newReviewers.length == firstGSPNumber, "Incorrect number of reviewers provided");
    for (uint i = 0; i < newReviewers.length; i++) {
        Reviewers.push(newReviewers[i]);
        _addReviewerToSelectedManuscripts(newReviewers[i], hash_Id_Manuscript);
    }}

 // PostulationSelection()

    bytes32[] ReviewOpenings;
    uint postulationcounter=0;


    function createReviewOpenings(bytes32 idManuscriptProcess) private{
        ReviewOpenings.push(idManuscriptProcess);
    }

    function postulate() public returns (bytes32) {
        require(ReviewOpenings.length*firstGSPNumber > postulationcounter, "No review openings available");
        postulationcounter+=1;
        return ReviewOpenings[postulationcounter/firstGSPNumber];}

 // RATINGSelection

    mapping(address => uint) public ReviewersRatings;
    mapping(address => bool) public availability;

    function rate(address reviewer, uint rating) private {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5."); //aqui falta modificar para que sea un promedio el rating
        ReviewersRatings[reviewer] = rating;
    }


    function RatingSelection(address[] storage result, uint num, bytes32 hash_Id_Manuscript) private returns (address[] memory) {
        uint length = Reviewers.length;

        // Make a copy of the ratings list to restore it later
        address[] memory originalReviewers = new address[](length);
        for (uint i = 0; i < length; i++) {
            originalReviewers[i] = Reviewers[i];
        }
        for (uint i = 0; i < length && i < num; i++) {
            uint maxRating = ReviewersRatings[Reviewers[0]];
            address bestRated = Reviewers[0];
            for (uint j = 1; j < Reviewers.length; j++) {
                if (ReviewersRatings[Reviewers[j]] > maxRating && availability[Reviewers[j]]) {
                    maxRating = ReviewersRatings[Reviewers[j]];
                    bestRated = Reviewers[j];
                }
            }
            result[i] = bestRated;
            _addReviewerToSelectedManuscripts(bestRated, hash_Id_Manuscript);

            // Remove the best-rated address from the list so that it's not included again
            for (uint j = 0; j < Reviewers.length; j++) {
                if (Reviewers[j] == bestRated) {
                    if (j < Reviewers.length - 1) {
                        Reviewers[j] = Reviewers[Reviewers.length - 1];
                    }
                    Reviewers.pop();
                    break;
                }
            }
        }
        // Restore the ratings list to its original state
        for (uint i = 0; i < length; i++) {
            Reviewers[i] = originalReviewers[i];
        }
        return result;
    }

 // EDITOR SELECTION
    function EditorSelection(address[] storage array, bytes32 hash_Id_Manuscript) internal{
        uint random = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % Editors.length);
        array.push(Editors[random]);
        _addReviewerToSelectedManuscripts(Editors[random], hash_Id_Manuscript);
    }


 //Select The Protocol for FGSP and SGSP

    event NewProcessAvailable(string processType);

    function RGSelection(address[] storage array, bool SG, uint amount, bytes32 hash_Id_Manuscript) private {
        string memory option = firstGSP;
        if (SG){
            option = secondGSP;
        }
        if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Random")))) {
            RandomSelection(array, amount, hash_Id_Manuscript);
        } else if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Rating")))) {
            RatingSelection(array, amount, hash_Id_Manuscript);
        } else if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Editor")))) {
            EditorSelection(array, hash_Id_Manuscript);
        } 
        
        else if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Designation")))) {
            createReviewOpeningsForAssign(hash_Id_Manuscript);
            emit NewProcessAvailable("A new process needs a editor to assign the reviewers");
        }

        else if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Postulation")))) {
            if (!SG){
            createReviewOpenings(hash_Id_Manuscript);
            emit NewProcessAvailable("A new process is available to postulate in a First Review Group");
            } else{
            createReviewOpenings(hash_Id_Manuscript);
            emit NewProcessAvailable("A new process is available to postulate in a Second Review Group");
            }
        } 
    }
    
 // TIPP -------------------
/*
    uint256 public rewardRate = 10; // 10% reward rate for completed Processes

    enum TIPPStatus {Staked, Incentive, Penalty}

    struct TIPP {
        address user;
        uint256 stake;
        TIPPStatus status;
    }

    mapping(bytes32 => TIPP) public TIPPs;
    mapping(address => bytes32[]) public userTIPPs;



    function createTIPP(uint256 _stake, bytes32 _idManuscript) public {
        require(_stake > 0, "Stake must be greater than 0");
        require(_stake <= 20 * (10 ** uint256(token.decimals())), "Maximum stake is 20 tokens");

        token.transferFrom(msg.sender, address(this), _stake);
        bytes32 TIPPId = keccak256(abi.encodePacked(_idManuscript, msg.sender));

        TIPP memory newTIPP = TIPP({
            user: msg.sender,
            stake: _stake,
            status: TIPPStatus.Staked
        });

        TIPPs[TIPPId] = newTIPP;
        userTIPPs[msg.sender].push(TIPPId);
    }

    function updateTIPP(bytes32 _TIPPId, bool _incentive) private {
        TIPP storage tipp = TIPPs[_TIPPId];

        if (_incentive) {
            tipp.status = TIPPStatus.Incentive;
            uint256 reward = (tipp.stake * rewardRate) / 100;
            token.transfer(tipp.user, tipp.stake + reward);
        } else {
            tipp.status = TIPPStatus.Penalty;
        }
    }
*/



//--------------------Manuscript Submission-------------

    function UploadManuscript(
        address _authors,
        string memory _title,
        string memory _filelink
        //uint256 _payment
    ) public {
        //require(_payment >= submissionfee, "Submission fee is 10 tokens");
        //token.transferFrom(msg.sender, address(this), _payment);

        ManuscriptProcess memory newManuscript = ManuscriptProcess({
            primaryauthor: msg.sender,
            authors: _authors,
            title: _title,
            filelink: _filelink,
            paid: true,
            fgreviewers: new address[](firstGSPNumber),
            fgdecision: new ManuscriptDecision[](firstGSPNumber),
            fgdecisionlink: new string[](firstGSPNumber),
            sgreviewers: new address[](secondGSPNumber),
            sgdecision: new ManuscriptDecision[](secondGSPNumber),
            sgdecisionlink: new string[](secondGSPNumber),
            state: ManuscriptDecision.InProcess,
            nstate: 0,
            previousreviewaddress: bytes32(0)
        });

        bytes32 Hash_Id_Manuscript = keccak256(abi.encodePacked(msg.sender, _title, _filelink));

        ManuscriptProcesses[Hash_Id_Manuscript] = newManuscript;

        RGSelection(ManuscriptProcesses[Hash_Id_Manuscript].fgreviewers, false, firstGSPNumber, Hash_Id_Manuscript);
        RGSelection(ManuscriptProcesses[Hash_Id_Manuscript].sgreviewers, true, secondGSPNumber, Hash_Id_Manuscript);

    }



//--------------------First
 //CheckPendingsReviews
    function getSelectedManuscriptProcesses() public view returns (bytes32[] memory) {
        return reviewerSelectedManuscripts[msg.sender];
    }


 // AcceptOrRejectReview
    function acceptOrRejectReview(bytes32 manuscriptHash, bool accept) public {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        
        bool isReviewer = false;
        bool isFirstGroup = false;
        uint reviewerIndex;
        
        for (uint i = 0; i < manuscript.fgreviewers.length; i++) {
            if (manuscript.fgreviewers[i] == msg.sender) {
                isReviewer = true;
                isFirstGroup = true;
                reviewerIndex = i;
                break;
            }
        }
        
        if (!isReviewer) {
            for (uint i = 0; i < manuscript.sgreviewers.length; i++) {
                if (manuscript.sgreviewers[i] == msg.sender) {
                    isReviewer = true;
                    isFirstGroup = false;
                    reviewerIndex = i;
                    break;
                }
            }
        }
        
        require(isReviewer, "You are not a reviewer for this manuscript");
        
        if (accept) {
            //if (isFirstGroup && keccak256(abi.encodePacked((ip))) == keccak256(abi.encodePacked(("TIPP")))){
                //require(TIPPs[keccak256(abi.encodePacked(manuscriptHash, msg.sender))].status==TIPPStatus.Staked, "You have to stake first");
            //}
        } else {
            // Reviewer has rejected, replace them.
            replaceReviewer(manuscriptHash, isFirstGroup, reviewerIndex, 1);
        }
    }

    function replaceReviewer(bytes32 manuscriptHash, bool isFirstGroup, uint reviewerIndex, uint amount) internal {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        address[] storage reviewers = isFirstGroup ? manuscript.fgreviewers : manuscript.sgreviewers;
        
        // Remove the reviewer from the list
        removeItem(reviewers, reviewers[reviewerIndex]);
        
        // Add a new reviewer based on the review selection protocol
        bool isSecondGroup = !isFirstGroup;
        RGSelection(reviewers, isSecondGroup, amount, manuscriptHash);
    }

 //UploadReview
    function submitFirstGroupReview(bytes32 manuscriptHash, ManuscriptDecision decision, string memory decisionLink) public {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        
        bool isReviewer = false;
        for (uint i = 0; i < manuscript.fgreviewers.length; i++) {
            if (manuscript.fgreviewers[i] == msg.sender) {
                isReviewer = true;
                break;
            }
        }
        
        require(isReviewer, "You are not part of the first group reviewers");
        
        manuscript.fgdecision.push(decision);
        manuscript.fgdecisionlink.push(decisionLink);
        manuscript.nstate+=1;
    }

//GET THE PAPER
    function getManuscriptFile(bytes32 manuscriptHash) public view returns (string memory) {
        return ManuscriptProcesses[manuscriptHash].filelink;
    }
//Second

 //Upload
    function submitSecondGroupReview(bytes32 manuscriptHash, ManuscriptDecision decision, string memory decisionLink) public {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        
        bool isReviewer = false;
        for (uint i = 0; i < manuscript.sgreviewers.length; i++) {
            if (manuscript.sgreviewers[i] == msg.sender) {
                isReviewer = true;
                break;
            }
        }
        
        require(isReviewer, "You are not part of the second group reviewers.");
        require(ManuscriptProcesses[manuscriptHash].nstate>=firstGSPNumber, "The 1st review procees is not over yet.");
        manuscript.sgdecision.push(decision);
        manuscript.sgdecisionlink.push(decisionLink);
        if (ManuscriptProcesses[manuscriptHash].nstate==secondGSPNumber+firstGSPNumber){
            finalizeReview(manuscriptHash);
        }
    }


 //GET THE REVIEW PAPER
    function get1gReviewFile(bytes32 manuscriptHash) public view returns (string[] memory) {
        return ManuscriptProcesses[manuscriptHash].fgdecisionlink;
    }


//RESULTS

    function analyzeSGDecisions(bytes32 manuscriptHash) private {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];

        uint256[] memory decisionCounts = new uint256[](uint256(ManuscriptDecision.Accept));

        for (uint256 i = 0; i < manuscript.sgdecision.length; i++) {
            decisionCounts[uint256(manuscript.sgdecision[i])]++;
        }

        uint256 maxCount = 0;
        uint256 maxIndex = 0;

        for (uint256 i = 0; i < decisionCounts.length; i++) {
            if (decisionCounts[i] > maxCount) {
                maxCount = decisionCounts[i];
                maxIndex = i;
            }
        }

        manuscript.state = ManuscriptDecision(maxIndex);
    }


    event ManuscriptProcessCompleted(string state);


    function finalizeReview(bytes32 manuscriptHash) public {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        analyzeSGDecisions(manuscriptHash);

       if (manuscript.state == ManuscriptDecision.Accept) {
            // Update TIPP for the primary author
            //if (keccak256(abi.encodePacked((ip))) == keccak256(abi.encodePacked(("TIPP")))){
            //bytes32 TIPPId = keccak256(abi.encodePacked(manuscriptHash, manuscript.primaryauthor));
            //updateTIPP(TIPPId, true);}
            emit ManuscriptProcessCompleted("The manuscript was accepted.");
        } else if (manuscript.state == ManuscriptDecision.Reject){
            // Update TIPP for the primary author
            //bytes32 TIPPId = keccak256(abi.encodePacked(manuscriptHash, manuscript.primaryauthor));
            //updateTIPP(TIPPId, false);
            emit ManuscriptProcessCompleted("The manuscript was rejected.");

        } else if (manuscript.state == ManuscriptDecision.ChangesRequired){
            emit ManuscriptProcessCompleted("The manuscript requieres some changes.");
        }
    }

}