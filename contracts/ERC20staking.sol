// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract StakingContract {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        bool active;
    }

    mapping(address => Stake) public stakes;

    ERC20 public token;
    address public owner;
    uint256 public interestRate; // interest rate in percent (e.g., 5 for 5%)

    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _tokenAddress, uint256 _interestRate) {
        token = ERC20(_tokenAddress);
        owner = msg.sender;
        interestRate = _interestRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function stake(uint256 _amount, uint256 _duration) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakes[msg.sender].amount == 0, "Already staked"); // Only one stake at a time allowed

        // Transfer tokens from user to contract
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        stakes[msg.sender] = Stake({
            amount: _amount,
            startTime: block.timestamp,
            duration: _duration,
            active: true
        });

        emit Staked(msg.sender, _amount, _duration);
    }

    function calculateInterest(uint256 _amount, uint256 _duration) internal view returns (uint256) {
        return (_amount * interestRate * _duration) / (365 days * 100);
    }

    function withdraw() external {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.active, "No active stake");

        uint256 interest = calculateInterest(userStake.amount, block.timestamp - userStake.startTime);
        uint256 totalAmount = userStake.amount + interest;

        // Remove stake
        delete stakes[msg.sender];

        // Transfer tokens to user

        require(token.transfer(msg.sender, totalAmount), "Transfer failed");

        emit Withdrawn(msg.sender, totalAmount);
    }

    function setInterestRate(uint256 _interestRate) external onlyOwner {
        interestRate = _interestRate;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    // Emergency function to withdraw stuck tokens
    function emergencyWithdraw(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        ERC20(_tokenAddress).transfer(_to, _amount);
    }
}
