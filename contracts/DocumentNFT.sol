// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DocumentNFT is ERC721URIStorage, Ownable {
    uint256 public docCount;
    address public rwaContract;

    constructor(address initialOwner) ERC721("DocumentNFT", "DOC") Ownable(initialOwner) {}

    function setRWAContract(address _rwaContract) external onlyOwner {
        require(_rwaContract != address(0), "Invalid address");
        rwaContract = _rwaContract;
    }

    function mintDocument(address owner, string memory documentURI) external returns (uint256) {
        require(msg.sender == rwaContract, "Unauthorized caller");

        docCount++;
        uint256 documentId = docCount;
        _mint(owner, documentId);
        _setTokenURI(documentId, documentURI);

        return documentId;
    }
}
