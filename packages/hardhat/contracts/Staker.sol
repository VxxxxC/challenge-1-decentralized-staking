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
    bool public openForWithdraw = false;

    struct Stakers {
        address stakerAddress;
    }

    Stakers[] stakers;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    function stake() external payable {
        require(!executed && !openForWithdraw);
        require(msg.value > 0.0001 ether, "You must at least send 0.0001 ETH !!");
        balance[address(this)] += msg.value;
        emit Stake(msg.sender, msg.value);
        if (!checkStaker(msg.sender)) {
            stakers.push(Stakers(msg.sender));
        }
    }

    event Stake(address, uint256);

    function execute() external expireDeadline notCompleted {
        if (balance[address(this)] > threshold) {
            require(!executed, "Already executed..");
            exampleExternalContract.complete{ value: balance[address(this)] }();
            executed = true;
            balance[address(this)] = 0;
        } else {
            if (openForWithdraw) return revert("Please withdraw your funds, as your stake is less than 1 ETH");
            openForWithdraw = true;
        }
    }

    function withdraw() external expireDeadline notCompleted {
        require(openForWithdraw, "withdrawal not open yet...");
        destroy(msg.sender);
    }

    function destroy(address apocalypse) internal {
        selfdestruct(payable(apocalypse));
        balance[address(this)] = 0;
        executed = false;
        openForWithdraw = false;
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
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i].stakerAddress == input) {
                return true;
            }
        }
        return false;
    }

    modifier expireDeadline() {
        require(block.timestamp > deadline, "Deadline not pass yet...");
        _;
    }

    modifier notCompleted() {
        require(exampleExternalContract.completed() == false, "staking contract execute completed..");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
}
