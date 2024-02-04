// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "stl-contracts/ERC/ERC5169.sol";

contract ERC721Mint is Ownable, ERC5169, ERC721Enumerable {

constructor()
ERC721("hahaha", "hahaha")  //请把里面的hahaha替换成你的昵称，不要都搞一样了！！！
Ownable(msg.sender)
{}
function supportsInterface(bytes4 interfaceId) public view override(ERC5169, ERC721Enumerable) returns (bool) {

return ERC721Enumerable.supportsInterface(interfaceId) || ERC5169.supportsInterface(interfaceId);
}
// limit set contracts to admin only
function _authorizeSetScripts(string[] memory) internal view override(ERC5169) onlyOwner {}

function safeMint(address to, uint256 tokenId) public onlyOwner {
_safeMint(to, tokenId);

}
}

