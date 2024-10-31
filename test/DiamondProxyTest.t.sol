// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DiamondProxy.sol";
import "../src/facets/NFTLendingFacet.sol";
import "../src/interfaces/IERC721.sol";

contract DiamondProxyTest is Test {
    DiamondProxy proxy;
    NFTLendingFacet lendingFacet;

    function setUp() public {
        proxy = new DiamondProxy();
        lendingFacet = new NFTLendingFacet();

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = NFTLendingFacet.createLoan.selector;
        selectors[1] = NFTLendingFacet.repayLoan.selector;

        proxy.addFacet(address(lendingFacet), selectors);
    }

    function testFacetAddedSuccessfully() public {
        (bool success, ) = address(proxy).call(
            abi.encodeWithSignature(
                "createLoan(address,uint256,uint256,uint256,uint256)",
                address(0),
                0,
                1 ether,
                5,
                30
            )
        );
        assertFalse(success);
    }
}
