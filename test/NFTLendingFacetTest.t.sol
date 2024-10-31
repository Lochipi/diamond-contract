// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/facets/NFTLendingFacet.sol";
import "../src/interfaces/IERC721.sol";

contract MockERC721 is IERC721 {
    mapping(uint256 => address) public tokenOwners;
    mapping(uint256 => address) public tokenApprovals;

    function mint(address to, uint256 tokenId) external {
        tokenOwners[tokenId] = to;
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        return tokenOwners[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        require(tokenOwners[tokenId] == from, "Not the owner");
        require(
            msg.sender == from || msg.sender == tokenApprovals[tokenId],
            "Not approved"
        );
        tokenOwners[tokenId] = to;
    }

    function approve(address to, uint256 tokenId) external {
        require(msg.sender == tokenOwners[tokenId], "Not the owner");
        tokenApprovals[tokenId] = to;
    }
}

contract NFTLendingFacetTest is Test {
    NFTLendingFacet lendingFacet;
    MockERC721 mockNFT;

    address borrower = address(1);
    uint256 nftId = 1;
    uint256 loanAmount = 1 ether;
    uint256 interestRate = 5;
    uint256 loanDuration = 30 days;

    function setUp() public {
        lendingFacet = new NFTLendingFacet();
        mockNFT = new MockERC721();

        mockNFT.mint(borrower, nftId);
    }

    function testCreateLoan() public {
        vm.deal(borrower, 10 ether);

        vm.startPrank(borrower);
        mockNFT.approve(address(lendingFacet), nftId);

        lendingFacet.createLoan(
            address(mockNFT),
            nftId,
            loanAmount,
            interestRate,
            loanDuration
        );

        (
            uint256 loanId,
            uint256 loanNftId,
            address nftAddress,
            address loanBorrower,
            uint256 amount,
            uint256 rate,
            uint256 duration,
            bool active
        ) = lendingFacet.loans(0);
        assertEq(loanNftId, nftId);
        assertEq(nftAddress, address(mockNFT));
        assertEq(loanBorrower, borrower);
        assertEq(amount, loanAmount);
        assertEq(rate, interestRate);
        assertEq(duration, loanDuration);
        assertTrue(active);

        vm.stopPrank();
    }

    function testRepayLoan() public {
        vm.deal(borrower, 10 ether);

        // Simulating borrower creating a loan
        vm.startPrank(borrower);
        mockNFT.approve(address(lendingFacet), nftId);

        lendingFacet.createLoan(
            address(mockNFT),
            nftId,
            loanAmount,
            interestRate,
            loanDuration
        );

        // Calculate total repayment amount and fund borrower
        uint256 totalRepayment = loanAmount +
            ((loanAmount * interestRate) / 100);

        // Fund borrower account with repayment amount
        payable(borrower).transfer(totalRepayment);

        // Call repayLoan function
        lendingFacet.repayLoan(0);

        // Verify loan is marked as repaid
        (, , , , , , , bool active) = lendingFacet.loans(0);
        assertFalse(active, "Loan should be inactive after repayment");

        // Verify NFT ownership is returned to the borrower
        assertEq(mockNFT.ownerOf(nftId), borrower);

        vm.stopPrank();
    }
}
