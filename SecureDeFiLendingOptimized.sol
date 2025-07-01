// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SecureDeFiLendingOptimized is ReentrancyGuard, Ownable {
    uint public loanCounter;
    uint constant MAX_REPUTATION = 10;
    uint constant COLLATERAL_RATIO = 20; // 20%
    uint constant REWARD_RATE = 1;       // 1% of collateral
    uint constant LATE_FEE_PER_DAY = 5;  // 0.5% per day = 5/1000
    uint constant GRACE_PERIOD = 6 days;
    uint constant COOLDOWN_PERIOD = 3 days;
    uint constant MIN_LOAN_DURATION_DAYS = 1;
    uint constant MAX_LOAN_DURATION_DAYS = 30;

    mapping(address => BorrowerProfile) public borrowers;
    mapping(uint => Loan) public loans;
    mapping(uint => uint) public interestRateCurve;

    string public interestRateIPFSCID;
    address public oracle;

    struct Loan {
        uint id;
        address borrower;
        uint principal;
        uint interestRate;
        uint startTime;
        uint duration;
        uint collateral;
        bool repaid;
        bool defaulted;
    }

    struct BorrowerProfile {
        uint reputation;
        uint totalLoans;
        uint activeLoanId;
        uint cooldownUntil;
    }

    event LoanIssued(uint loanId, address borrower, uint amount, uint interestRate);
    event LoanRepaid(uint loanId, address borrower, uint repaidAmount, uint lateFee);
    event LoanDefaulted(uint loanId, address borrower);
    event ReputationUpdated(address borrower, uint newScore);
    event InterestRateCurveUpdated(uint rep, uint bps);
    event IPFSCIDUpdated(string cid);

    constructor() Ownable(msg.sender) {
    for (uint i = 0; i <= MAX_REPUTATION; i++) {
        uint[11] memory defaultRates = [uint(3230), 2890, 2340, 1870, 1320, 1140, 910, 870, 720, 690, 600];
        interestRateCurve[i] = defaultRates[i];
    }
}


    modifier onlyValidRep(uint rep) {
        require(rep <= MAX_REPUTATION, "Invalid reputation");
        _;
    }

    modifier onlyBorrower(uint loanId) {
        require(loans[loanId].borrower == msg.sender, "Not your loan");
        _;
    }

    function setInterestRateCurve(uint rep, uint bps) external onlyOwner onlyValidRep(rep) {
        interestRateCurve[rep] = bps;
        emit InterestRateCurveUpdated(rep, bps);
    }

    function updateIPFSCID(string memory _cid) external onlyOwner {
        interestRateIPFSCID = _cid;
        emit IPFSCIDUpdated(_cid);
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function lenderWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getInterestRate(uint rep) public view onlyValidRep(rep) returns (uint) {
        return interestRateCurve[rep];
    }

    function requestLoan(uint _durationInDays) external payable nonReentrant {
        require(msg.value > 0, "Zero collateral");
        require(_durationInDays >= MIN_LOAN_DURATION_DAYS && _durationInDays <= MAX_LOAN_DURATION_DAYS, "Invalid loan duration");

        BorrowerProfile storage bp = borrowers[msg.sender];
        require(block.timestamp >= bp.cooldownUntil, "Cooldown active");
        require(bp.activeLoanId == 0, "Existing loan open");

        if (bp.reputation == 0) {
            bp.reputation = 5;
        }

        uint rep = bp.reputation > MAX_REPUTATION ? MAX_REPUTATION : bp.reputation;
        uint interestRate = interestRateCurve[rep];
        uint principal = (msg.value * 100) / COLLATERAL_RATIO;
        uint duration = _durationInDays * 1 days;

        loanCounter++;
        loans[loanCounter] = Loan({
            id: loanCounter,
            borrower: msg.sender,
            principal: principal,
            interestRate: interestRate,
            startTime: block.timestamp,
            duration: duration,
            collateral: msg.value,
            repaid: false,
            defaulted: false
        });

        bp.totalLoans++;
        bp.activeLoanId = loanCounter;

        payable(msg.sender).transfer(principal);
        emit LoanIssued(loanCounter, msg.sender, principal, interestRate);
    }

    function repayLoan() external payable nonReentrant {
        BorrowerProfile storage bp = borrowers[msg.sender];
        uint loanId = bp.activeLoanId;
        require(loanId != 0, "No active loan");

        Loan storage loan = loans[loanId];
        require(!loan.repaid && !loan.defaulted, "Already closed");
        require(loan.borrower == msg.sender, "Not borrower");

        (uint totalDue, uint lateFee) = _calculateRepayment(
            loan.principal,
            loan.interestRate,
            loan.startTime,
            loan.duration
        );

        require(msg.value >= totalDue, "Insufficient amount");

        loan.repaid = true;
        bp.cooldownUntil = block.timestamp + COOLDOWN_PERIOD;
        bp.reputation = bp.reputation < MAX_REPUTATION ? bp.reputation + 1 : MAX_REPUTATION;

        // Reward borrower
        uint reward = (loan.collateral * REWARD_RATE) / 100;
        payable(msg.sender).transfer(loan.collateral + reward);

        emit LoanRepaid(loanId, msg.sender, msg.value, lateFee);
        emit ReputationUpdated(msg.sender, bp.reputation);
        bp.activeLoanId = 0;
    }

    function markAsDefaulted(uint loanId) external onlyOwner {
        Loan storage loan = loans[loanId];
        require(!loan.repaid && !loan.defaulted, "Already resolved");

        uint deadline = loan.startTime + loan.duration + GRACE_PERIOD;
        require(block.timestamp > deadline, "Grace period ongoing");

        loan.defaulted = true;

        BorrowerProfile storage bp = borrowers[loan.borrower];
        bp.reputation = bp.reputation >= 2 ? bp.reputation - 2 : 0;
        bp.activeLoanId = 0;
        bp.cooldownUntil = block.timestamp + 5 days;

        emit LoanDefaulted(loanId, loan.borrower);
        emit ReputationUpdated(loan.borrower, bp.reputation);
    }

    function _calculateRepayment(
        uint principal,
        uint rate,
        uint startTime,
        uint duration
    ) internal view returns (uint totalDue, uint lateFee) {
        uint elapsed = block.timestamp - startTime;
        uint interest = (principal * rate * elapsed) / (1 days * 10000);
        totalDue = principal + interest;

        if (elapsed > duration) {
            uint lateDays = (elapsed - duration) / 1 days;
            require(lateDays <= 6, "Grace period exceeded");
            lateFee = (principal * lateDays * LATE_FEE_PER_DAY) / 1000;
            totalDue += lateFee;
        }
    }

    receive() external payable {}
}

