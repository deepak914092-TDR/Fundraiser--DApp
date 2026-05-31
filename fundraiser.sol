// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Fundraiser {
    string public title;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalRaised;
    bool public withdrawn;
    address public owner;
    mapping(address => uint256) public donations;

    event Donated(address indexed donor, uint256 amount, uint256 newTotal);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event Refunded(address indexed donor, uint256 amount);

    constructor(
        string memory _title,
        string memory _description,
        uint256 _goalInWei,
        uint256 _durationSeconds
    ) {
        title = _title;
        description = _description;
        goal = _goalInWei;
        deadline = block.timestamp + _durationSeconds;
        owner = msg.sender;
    }

    function donate() external payable {
        require(block.timestamp < deadline, "Campaign ended");
        require(msg.value > 0, "Send ETH");
        donations[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Donated(msg.sender, msg.value, totalRaised);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        require(totalRaised >= goal, "Goal not reached");
        require(!withdrawn, "Already withdrawn");
        withdrawn = true;
        uint256 amount = address(this).balance;
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
        emit FundsWithdrawn(owner, amount);
    }

    function refund() external {
        require(block.timestamp >= deadline, "Still active");
        require(totalRaised < goal, "Goal reached");
        uint256 amount = donations[msg.sender];
        require(amount > 0, "No donation");
        donations[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
        emit Refunded(msg.sender, amount);
    }

    function getStatus()
        external
        view
        returns (
            bool isActive,
            bool goalReached,
            uint256 remaining,
            uint256 timeLeft
        )
    {
        isActive = block.timestamp < deadline;
        goalReached = totalRaised >= goal;
        remaining = goal > totalRaised ? goal - totalRaised : 0;
        timeLeft = block.timestamp < deadline ? deadline - block.timestamp : 0;
    }
}