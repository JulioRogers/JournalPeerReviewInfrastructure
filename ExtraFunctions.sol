pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProcessTIPPCheckSystem {

    function getManuscriptDetails(bytes32 hash) public view returns (ManuscriptProcess memory) {
        return ManuscriptProcesses[hash];
    }

    function submitFirstGroupReview(bytes32 manuscriptHash, string memory decision, string memory decisionLink) public {
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
    }

    function submitSecondGroupReview(bytes32 manuscriptHash, string memory decision, string memory decisionLink) public {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        
        bool isReviewer = false;
        for (uint i = 0; i < manuscript.sgreviewers.length; i++) {
            if (manuscript.sgreviewers[i] == msg.sender) {
                isReviewer = true;
                break;
            }
        }
        
        require(isReviewer, "You are not part of the second group reviewers");
        
        manuscript.sgdecision.push(decision);
        manuscript.sgdecisionlink.push(decisionLink);
    }

    function finalizeReview(bytes32 manuscriptHash, bool approved) public {
        require(IsEditor[msg.sender], "Only editors can finalize the review");
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        
        if (approved) {
            manuscript.state = "approved";
            // Update TIPP for the primary author
            bytes32 TIPPId = keccak256(abi.encodePacked(manuscriptHash, manuscript.primaryauthor));
            updateTIPP(TIPPId, true);
        } else {
            manuscript.state = "rejected";
            // Update TIPP for the primary author
            bytes32 TIPPId = keccak256(abi.encodePacked(manuscriptHash, manuscript.primaryauthor));
            updateTIPP(TIPPId, false);
        }
    }

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
            // Reviewer has accepted, no further action required.
        } else {
            // Reviewer has rejected, replace them.
            replaceReviewer(manuscriptHash, isFirstGroup, reviewerIndex);
        }
    }

    function replaceReviewer(bytes32 manuscriptHash, bool isFirstGroup, uint reviewerIndex) internal {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        address[] storage reviewers = isFirstGroup ? manuscript.fgreviewers : manuscript.sgreviewers;
        
        // Remove the reviewer from the list
        removeItem(reviewers, reviewers[reviewerIndex]);
        
        // Add a new reviewer based on the review selection protocol
        bool isSecondGroup = !isFirstGroup;
        RGSelection(reviewers, isSecondGroup);
    }


}

contract JPRI {
    // ...

    // Mapping to store reviewer selections
    mapping(address => bytes32[]) public reviewerSelectedManuscripts;

    function _addReviewerToSelectedManuscripts(address reviewer, bytes32 manuscriptHash) private {
        reviewerSelectedManuscripts[reviewer].push(manuscriptHash);
    }

    // Update the RGSelection function to call _addReviewerToSelectedManuscripts
    function RGSelection(address[] storage array, bool SG) private {
        // ...
        if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Random")))) {
            RandomSelection(array, amount);
        } else if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Rating")))) {
            RatingSelection(array, amount);
        } else if (keccak256(abi.encodePacked((option))) == keccak256(abi.encodePacked(("Editor")))) {
            EditorSelection(array);
        }
        // ...

        for (uint i = 0; i < array.length; i++) {
            _addReviewerToSelectedManuscripts(array[i], Hash_Id_Manuscript);
        }
    }

    // Function to get the selected manuscript process hashes for the caller
    function getSelectedManuscriptProcesses() public view returns (bytes32[] memory) {
        return reviewerSelectedManuscripts[msg.sender];
    }

    // ...
}
    function calculateEnumFrequencies(ManuscriptDecision[] memory arr) public pure returns (mapping(uint => uint) memory) {
        mapping(uint => uint) memory frequencies;
        uint total = arr.length;

        // Calculate frequencies
        for (uint i = 0; i < total; i++) {
            uint val = uint(arr[i]);
            frequencies[val]++;
        }

        // Calculate means
        mapping(uint => uint) memory means;
        for (uint i = 0; i < uint(MyEnum.THIRD) + 1; i++) {
            means[i] = frequencies[i] * 100 / total; // Calculate mean
        }

        return means;
    }

    function finalizeReview(bytes32 manuscriptHash) public {
        ManuscriptProcess storage manuscript = ManuscriptProcesses[manuscriptHash];
        

       // if (approved) {
            manuscript.state = "approved";
            // Update TIPP for the primary author
            bytes32 TIPPId = keccak256(abi.encodePacked(manuscriptHash, manuscript.primaryauthor));
            updateTIPP(TIPPId, true);
       // } else {
            manuscript.state = "rejected";
            // Update TIPP for the primary author
            bytes32 TIPPId = keccak256(abi.encodePacked(manuscriptHash, manuscript.primaryauthor));
            updateTIPP(TIPPId, false);
        }
    //}
    