// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ダイナミック傘連判状
 * @author tomoking
 * @notice ERC721
 */
contract MagicPlank is ERC721URIStorage, ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _robinCounter;

    //@notice 列挙型グレード
    enum Rarity {STANDARD, EPIC, LEGEND}

    //@notice ロビンごとの継承者数
    mapping(uint256 => uint256) RobinsToSuccessors;
    //@notice ロビンごとの継承者名マッピング
    mapping(uint256 => string) Successors; 
    //@notice ロビンごとのグレード
    mapping(uint256 => Rarity) public tokenIdToRarity;
    mapping(uint256 => address) toAddr;
    mapping(uint256 => string) strToAddr;

    //ユーザーデータ
    bytes32 public furi;
    bytes32 public luri;
    bytes32 public uname;
    string private _transitionUri;
    string private robinUri;
    string private baseUrl = "https://testnets-api.opensea.io/api/v1/assets?format=json&limit=1&offset=0&order_direction=desc&owner=";

    //Chainlinknode情報
    address private oracle;
    bytes32 private furi_jobId;
    bytes32 private luri_jobId;
    bytes32 private name_jobId;
    uint256 private fee;

    uint256 private currentRobinId;

    //@title コンストラクタ
    constructor(string memory initialUri_)ERC721("MagicPlank","MP"){
      _transitionUri = initialUri_;
      setPublicChainlinkToken();
      // Oracle address here
      oracle = 0x790E357227fa5936b894cBB7eb2Db8F10eddfD6b;
      // Job Id here
      furi_jobId = "c2e769e6008c427eb215508a46eee9f3";
      fee = 1 * 10 ** 18; 
    }

    /*
    * @title createPlainPlank
    * @notice ロビンのMintとinitialURIの設定
    * @dev RobinIdはCounterを使用
    */
    function createPlainPlank() public {
      //準備
      uint256 _RobinId = _robinCounter.current();
      Rarity initialEigenVal = Rarity(0);
      tokenIdToRarity[_RobinId] = initialEigenVal;
      RobinsToSuccessors[_RobinId] = 0;

      _safeMint(_msgSender(), _RobinId);
      _setTokenURI(_RobinId, _transitionUri);

      _robinCounter.increment();
    }

    /*
    * @title createRobin
    * @notice ロビンのMintと継承
    * @dev RobinIdはCounterを使用
    */
    function createPlank() public {
      //準備
      uint256 _RobinId = _robinCounter.current();
      Rarity initialEigenVal = Rarity(0);
      tokenIdToRarity[_RobinId] = initialEigenVal;
      RobinsToSuccessors[_RobinId] = 1;
      uint256 successorId = RobinsToSuccessors[_RobinId];

      _safeMint(_msgSender(), _RobinId);
      _setTokenURI(_RobinId, _transitionUri);
      _change(successorId, _RobinId, _msgSender());

      RobinsToSuccessors[_RobinId] = RobinsToSuccessors[_RobinId].add(1);
      _robinCounter.increment();
    }

    /*
    * @title Inherit
    * @notice ロビンの継承
    * @param to 継承先のアドレス
    * @param robinId 継承するロビンのId
    * @dev ConsumerApiからprofileを取得して格納
    */
    function Inherit(
      address to,
      uint256 robinId
    ) public {
      _setTokenURI(robinId, _transitionUri);
      uint256 successorId = RobinsToSuccessors[robinId];
      RobinsToSuccessors[robinId] = RobinsToSuccessors[robinId].add(1);
      _change(successorId, robinId, to);
      transferFrom(_msgSender(), to, robinId);
    }

    /*
    * @title _change
    * @notice profileの更新
    * @param successorId 継承者数
    * @param robinId ロビンID
    * @dev url => _setTokenURI
    *      successor => Successors
    */
    function _change(uint256 successorId, uint256 robinId, address to) private {
      toAddr[robinId] = to;
      currentRobinId = robinId;
      requestfUri(robinId);
      requestlUri(robinId);
      requestName(robinId);
      _grading(robinId, successorId);
    }

    /*
    * @title _grading
    * @notice グレードの判定
    * @dev Successor = 0~2=>STANDARD, 3~9=>EPIC, 10~=>LEGEND
    */
    function _grading(uint256 robinId, uint256 successorId) private {
      if(successorId <= 2){
        tokenIdToRarity[robinId] = Rarity.STANDARD;
      }
      else if(successorId <= 9){
        tokenIdToRarity[robinId] = Rarity.EPIC;
      }
      else {
        tokenIdToRarity[robinId] = Rarity.LEGEND;
      }
    }

    /*
    * @title requestData
    * @notice apiにデータ取得をリクエスト
    * @return requestId 
    * @dev requestの経路 DynamicRountRobin => ChainlinkClient => Oracle
    * => Job(Chainlinknode) => api
    */
    function requestfUri(uint256 id) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(furi_jobId, address(this), this.fulfillfUri.selector);

        strToAddr[id] = addressToString(toAddr[id]);
        request.add("get", string(abi.encodePacked(baseUrl, strToAddr[id])));
        request.add("path_image", "assets,0,image_url");
        request.add("path_address", "assets,0,owner,address");
        request.add("path_name", "assets,0,owner,user,username");

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /*
    * @title requestData
    * @notice apiにデータ取得をリクエスト
    * @return requestId 
    * @dev requestの経路 DynamicRountRobin => ChainlinkClient => Oracle
    * => Job(Chainlinknode) => api
    */
    function requestlUri(uint256 id) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(luri_jobId, address(this), this.fulfilllUri.selector);

        strToAddr[id] = addressToString(toAddr[id]);
        request.add("get", string(abi.encodePacked(baseUrl, strToAddr[id])));
        request.add("path_image", "assets,0,image_url");
        request.add("path_address", "assets,0,owner,address");
        request.add("path_name", "assets,0,owner,user,username");

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /*
    * @title requestData
    * @notice apiにデータ取得をリクエスト
    * @return requestId 
    * @dev requestの経路 DynamicRountRobin => ChainlinkClient => Oracle
    * => Job(Chainlinknode) => api
    */
    function requestName(uint256 id) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(name_jobId, address(this), this.fulfillName.selector);

        strToAddr[id] = addressToString(toAddr[id]);
        request.add("get", string(abi.encodePacked(baseUrl, strToAddr[id])));
        request.add("path_image", "assets,0,image_url");
        request.add("path_address", "assets,0,owner,address");
        request.add("path_name", "assets,0,owner,user,username");

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /*
    * @title fulfill
    * @notice apiからデータを受け取ってコントラクトに格納する関数
    * @param _requestId 
    * @param _data bytes32のデータ群
    * @dev ChainlinkClientがこの関数を呼び出すことをbuildChainlinkRequest()で設定
    */
    function fulfillfUri(bytes32 _requestId, bytes32 _data) public recordChainlinkFulfillment(_requestId)
    {
        furi = _data;
        //データの分岐
        //ToDo
        // robinUri = toString(data);
        // _setTokenURI(currentRobinId, robinUri);
    }

    function fulfilllUri(bytes32 _requestId, bytes32 _data) public recordChainlinkFulfillment(_requestId){
      luri = _data;
    }

    function fulfillName(bytes32 _requestId, bytes32 _data) public recordChainlinkFulfillment(_requestId){
      uname = _data;
    }

    /*
    * @title multiFulfill
    * @notice apiから複数データを受け取ってコントラクトに格納する関数
    * @param _requestId 
    * @param _data bytes32のデータ群
    * @dev ChainlinkClientがこの関数を呼び出すことをbuildChainlinkRequest()で設定
    */
    function multiFulfill(
      bytes32 _requestId, bytes32 _uri1, bytes32 _uri2, bytes32 _username
      ) public recordChainlinkFulfillment(_requestId){
        string memory StrUri1 = toString(_uri1);
        string memory StrUri2 = toString(_uri2);
        Successors[currentRobinId] = toString(_username);
        robinUri = string(abi.encodePacked("https://ipfs.moralis.io:2053/ipfs/", StrUri1, StrUri2));
        _setTokenURI(currentRobinId, robinUri);
    }

    /*
    * @title toString
    * @notice bytes32 => string
    * @param _bytes32 oracleから渡されるbytes32のデータ
    * @return string
    * @dev 引数はマージンが右側のByteコードのみ
    */
    function toString(bytes32 _bytes32) public pure returns (string memory) {
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

    /*
    * @title addressToString
    * @notice address => string
    * @param _addr 継承先のアドレス
    * @return string apiurlに利用するアドレス文字列
    */
    function addressToString(address _addr) public pure returns(string memory) 
    {
      string memory result = Strings.toHexString(uint256(uint160(_addr)), 20);
      return result;
    }    

    function getSuccessors(uint256 robinId) public view returns(uint256){
      return RobinsToSuccessors[robinId].sub(1);
    }

    function getGrade(uint256 robinId) public view returns(Rarity){
      return tokenIdToRarity[robinId];
    }

    function getSuccessorName(uint256 robinId) public view returns(string memory){
      return Successors[robinId];
    }
}