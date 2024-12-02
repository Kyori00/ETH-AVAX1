// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract VotingSystem {
    address public owner;
    uint public proposalCount;

    struct Proposal {
        string description;
        uint voteCount;
        bool isActive;
    }
    //address mapping
    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => uint)) public votes;
    //events
    event ProposalCreated(uint proposalId, string description);
    event VoteCast(uint proposalId, address voter);
    event ProposalEnded(uint proposalId, bool success);
    event VotesRefunded(uint proposalId, address voter, uint amount);
    event ProposalReactivated(uint proposalId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function createProposal(string memory _description) public onlyOwner {
        require(bytes(_description).length > 0, "Description is required");
        proposalCount++;
        proposals[proposalCount] = Proposal(_description, 0, true);
        emit ProposalCreated(proposalCount, _description);
    }

    function castVote(uint _proposalId) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal ID not found");
        require(proposals[_proposalId].isActive, "Proposal is not active");
        votes[msg.sender][_proposalId]++;
        proposals[_proposalId].voteCount++;
        emit VoteCast(_proposalId, msg.sender);
    }

function endProposal(uint _proposalId) public onlyOwner {
    require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal ID not found");
    require(proposals[_proposalId].isActive, "Proposal has already ended");
    proposals[_proposalId].isActive = false;
    assert(proposals[_proposalId].isActive == false);
    emit ProposalEnded(_proposalId, proposals[_proposalId].voteCount > 0);
}


    function refundVotes(uint _proposalId) public {
        if (_proposalId == 0 || _proposalId > proposalCount) {
            revert("Proposal ID not found");
        }
        if (proposals[_proposalId].isActive) {
            revert("Proposal is still active");
        }
        uint refundAmount = votes[msg.sender][_proposalId];
        if (refundAmount == 0) {
            revert("No votes to refund");
        }
        votes[msg.sender][_proposalId] = 0;
        proposals[_proposalId].voteCount -= refundAmount;
        emit VotesRefunded(_proposalId, msg.sender, refundAmount);
    }

    function reactivateProposal(uint _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal ID not found");
        require(!proposals[_proposalId].isActive, "Proposal is already active");
        proposals[_proposalId].isActive = true;
        emit ProposalReactivated(_proposalId);
    }
}
