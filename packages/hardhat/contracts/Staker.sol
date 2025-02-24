// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balance;
    mapping(address => bool) withdrawal;
    mapping(address => bool) staked;
    bool public executed = false;

    struct Stakers {
        address stakerAddress;
    }

    Stakers[] stakers;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 30 seconds;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    function stake() external payable {
        require(msg.value > 0.1 ether, "You must at least send 0.1 ETH !!");
        balance[address(this)] += msg.value;
        emit Stake(msg.sender, msg.value);
        if (!checkStaker(msg.sender)) {
            stakers.push(Stakers(msg.sender));
        }
        withdrawal[msg.sender] = false;
        staked[msg.sender] = true;
    }

    event Stake(address, uint256);

    function execute() external expireDeadline {
        require(!executed, "Already executed..");
        require(balance[address(this)] >= threshold, "Balance threshold below 1 ETH..");
        exampleExternalContract.complete{ value: address(this).balance }();
        executed = true;
    }

    function withdraw() external expireDeadline {
        require(checkStaker(msg.sender), "You are not staked yet...");
        require(!withdrawal[msg.sender], "Already withdrawed..");
        require(balance[address(this)] < threshold, "Contract balance over threshold!");
        (bool s, ) = msg.sender.call{ value: balance[address(this)] }("");
        require(s);
        withdrawal[msg.sender] = true;
        staked[msg.sender] = false;
    }

    modifier expireDeadline() {
        require(block.timestamp > deadline, "Deadline not pass yet...");
        _;
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    receive() external payable {
        this.stake();
    }

    function checkStaker(address input) internal view returns (bool) {
        for (uint i = 0; i < stakers.length; i++) {
            if (stakers[i].stakerAddress == input) {
                return true;
            }
        }
        return false;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
}
