
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface IDocumentNFT {
    function mintDocument(address owner, string memory documentURI) external returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}