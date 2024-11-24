// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    uint256 public proposalCount;

    struct Proposal {
        string description;
        uint256 voteCount;
        bool isActive;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => uint256)) public votes; // Track votes by address and proposal ID

    event ProposalCreated(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address voter);
    event ProposalEnded(uint256 proposalId, bool success);
    event VotesRefunded(uint256 proposalId, address voter, uint256 amount);
    event ProposalReactivated(uint256 proposalId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function createProposal(string memory _description) public onlyOwner {
        require(bytes(_description).length > 0, "Description must not be empty");
        proposalCount++;
        proposals[proposalCount] = Proposal(_description, 0, true);
        emit ProposalCreated(proposalCount, _description);
    }

    function castVote(uint256 _proposalId) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].isActive, "Proposal is not active");

        votes[msg.sender][_proposalId]++;
        proposals[_proposalId].voteCount++;
        emit VoteCast(_proposalId, msg.sender);
    }

    function endProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].isActive, "Proposal is already ended");

        proposals[_proposalId].isActive = false;

        bool success = proposals[_proposalId].voteCount > 0;
        emit ProposalEnded(_proposalId, success);
    }

    function refundVotes(uint256 _proposalId) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(!proposals[_proposalId].isActive, "Proposal is still active");
        require(votes[msg.sender][_proposalId] > 0, "No votes to refund");

        uint256 refundAmount = votes[msg.sender][_proposalId];
        votes[msg.sender][_proposalId] = 0;
        proposals[_proposalId].voteCount -= refundAmount;

        assert(refundAmount > 0); // Ensure refund amount is valid
        emit VotesRefunded(_proposalId, msg.sender, refundAmount);
    }

    function reactivateProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(!proposals[_proposalId].isActive, "Proposal is already active");

        proposals[_proposalId].isActive = true;
        emit ProposalReactivated(_proposalId);
    }
}
