// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/DiamondStorage.sol";

contract DiamondProxy {
    using DiamondStorage for DiamondStorage.Storage;

    constructor() {
        DiamondStorage.Storage storage ds = DiamondStorage.diamondStorage();
        ds.owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == DiamondStorage.diamondStorage().owner,
            "Not owner"
        );
        _;
    }

    function addFacet(
        address _facet,
        bytes4[] memory _selectors
    ) external onlyOwner {
        DiamondStorage.Storage storage ds = DiamondStorage.diamondStorage();
        for (uint i = 0; i < _selectors.length; i++) {
            ds.selectorToFacet[_selectors[i]] = _facet;
        }
    }

    // `receive` function to log Ether received or keep the balance in contract
    receive() external payable {
        require(msg.value > 0, "No Ether sent");

        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        address facet = DiamondStorage.diamondStorage().selectorToFacet[
            msg.sig
        ];
        require(facet != address(0), "Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    event Received(address sender, uint256 amount);
}
