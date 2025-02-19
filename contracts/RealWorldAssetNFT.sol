// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDocumentNFT.sol";

contract RealWorldAssetNFT is ERC721URIStorage, Ownable, AccessControl {
    uint256 public rwaCount;
    address public documentContract;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint256 => uint256[]) private mappedDocuments;

    event NFTMinted(uint256 tokenId, string metadataURI);
    event DocumentLinked(uint256 rwaId, uint256 documentId);

    constructor(address initialOwner) ERC721("RealWorldAssetNFT", "RWA") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(ADMIN_ROLE, initialOwner); // Grant ADMIN_ROLE to the deployer
    }

    function setDocumentContract(address _documentContract) external onlyOwner {
        require(_documentContract != address(0), "Invalid address");
        documentContract = _documentContract;
    }

    function grantAdminRole(address admin) public onlyRole(ADMIN_ROLE) {
        require(admin != address(0), "Invalid address");
        grantRole(ADMIN_ROLE, admin);
    }


    function revokeAdminRole(address admin) public onlyRole(ADMIN_ROLE) {
        require(admin != address(0), "Invalid address");
        require(admin != msg.sender, "Cannot remove yourself as the last admin");
        revokeRole(ADMIN_ROLE, admin);
    }

    function mintRWA(string memory metadataURI, address nftOwner) public onlyRole(ADMIN_ROLE) returns (uint256) {
        require(nftOwner != address(0), "Invalid owner address");
        rwaCount++;
        uint256 tokenId = rwaCount;
        _mint(nftOwner, tokenId);
        _setTokenURI(tokenId, metadataURI);

        emit NFTMinted(tokenId, metadataURI);
        return tokenId;
    }

    function mintDocument(uint256 rwaId, string memory documentURI) public onlyRole(ADMIN_ROLE) returns (uint256) {
        require(ownerOf(rwaId) != address(0), "RWA does not exist");
        require(documentContract != address(0), "Document contract not set");

        uint256 documentId = IDocumentNFT(documentContract).mintDocument(msg.sender, documentURI);
        mappedDocuments[rwaId].push(documentId);

        emit DocumentLinked(rwaId, documentId);
        return documentId;
    }

    function getMappedDocuments(uint256 rwaId) public view returns (uint256[] memory) {
        return mappedDocuments[rwaId];
    }

    function getOwnerAndTokenURI(uint256 rwaId) public view returns (address, string memory) {
        require(ownerOf(rwaId) != address(0), "RWA does not exist");
        return (ownerOf(rwaId), tokenURI(rwaId));
    }

    function isAdmin(address user) public view returns (bool) {
        return hasRole(ADMIN_ROLE, user);
    }

    function getAllTokenURIsForRWA(uint256 rwaId) public view returns (string memory, string[] memory) {
        require(ownerOf(rwaId) != address(0), "RWA does not exist");
        require(documentContract != address(0), "Document contract not set");

        uint256[] memory documentIds = mappedDocuments[rwaId];
        string memory rwaTokenURI = tokenURI(rwaId);
        string[] memory documentURIs = new string[](documentIds.length);

        for (uint256 i = 0; i < documentIds.length; i++) {
            documentURIs[i] = IDocumentNFT(documentContract).tokenURI(documentIds[i]);
        }

        return (rwaTokenURI, documentURIs);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
