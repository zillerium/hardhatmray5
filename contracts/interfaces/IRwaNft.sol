// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IRwaNft is IERC721 {
    event NFTMinted(uint256 indexed tokenId, string metadataURI);
    event DocumentLinked(uint256 indexed rwaId, uint256 indexed documentId);

    struct RWADetails {
        address owner;
        string metadataURI;
        uint256[] documentIds;
    }

    function setDocumentContract(address _documentContract) external;

    function grantAdminRole(address admin) external;

    function revokeAdminRole(address admin) external;

    function mintRWA(string memory metadataURI, address nftOwner) external returns (uint256);

    function mintDocument(uint256 rwaId, string memory documentURI) external returns (uint256);

    function getMappedDocuments(uint256 rwaId) external view returns (uint256[] memory);

    function getOwnerAndTokenURI(uint256 rwaId) external view returns (address, string memory);

    function isAdmin(address user) external view returns (bool);

    function getAllTokenURIsForRWA(uint256 rwaId) external view returns (string memory, string[] memory);
}
