// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/DiamondStorage.sol";
import "../interfaces/IERC721.sol";

contract NFTLendingFacet {
    struct Loan {
        uint256 loanId;
        uint256 nftId;
        address nftAddress;
        address borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        bool active;
    }

    DiamondStorage.Storage internal ds;
    uint256 public loanCounter;
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256) public balances;

    event LoanCreated(uint256 loanId, address borrower, uint256 amount);
    event LoanRepaid(uint256 loanId, address borrower, uint256 amount);

    function createLoan(
        address _nftAddress,
        uint256 _nftId,
        uint256 _amount,
        uint256 _interestRate,
        uint256 _duration
    ) external {
        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_nftId) == msg.sender, "Not the owner");

        nft.transferFrom(msg.sender, address(this), _nftId);
        loans[loanCounter] = Loan({
            loanId: loanCounter,
            nftId: _nftId,
            nftAddress: _nftAddress,
            borrower: msg.sender,
            amount: _amount,
            interestRate: _interestRate,
            duration: _duration,
            active: true
        });

        loanCounter++;
        balances[msg.sender] += _amount;
        emit LoanCreated(loanCounter, msg.sender, _amount);
    }

    function repayLoan(uint256 _loanId) external {
        Loan storage loan = loans[_loanId];
        require(loan.borrower == msg.sender, "Not the borrower");
        require(loan.active, "Loan not active");

        uint256 totalRepayment = loan.amount +
            ((loan.amount * loan.interestRate) / 100);
        require(balances[msg.sender] >= totalRepayment, "Insufficient balance");

        balances[msg.sender] -= totalRepayment;
        loan.active = false;

        IERC721(loan.nftAddress).transferFrom(
            address(this),
            msg.sender,
            loan.nftId
        );
        emit LoanRepaid(_loanId, msg.sender, totalRepayment);
    }
}
