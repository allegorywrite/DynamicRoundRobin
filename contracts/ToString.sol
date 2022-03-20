// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ToString {

  function bytes32ToBytes(bytes32 _bytes32) public pure returns (bytes memory){
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
  }

  function bytes32ToBytesToString(bytes32 _bytes32) public pure returns (string memory){
      bytes memory bytesArray = bytes32ToBytes(_bytes32);
      string memory out1 = string(bytesArray);
      return out1;
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
  }

  function toString(bytes32 _bytes32) public pure 
  returns (string memory) {
    string memory out = string(abi.encodePacked(_bytes32));
    return out;
  }
}