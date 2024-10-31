// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DiamondStorage {
    struct Storage {
        mapping(bytes4 => address) selectorToFacet;
        address owner;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns (Storage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
