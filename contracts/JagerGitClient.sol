pragma solidity >=0.4.0 <0.7.0;

import "@chainlink/contracts/src/v0.4/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.4/vendor/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract JagerGitClient is ChainlinkClient, Ownable {
  uint256 constant private ORACLE_PAYMENT = 1 * LINK;
  address _oracle;
  string _jobId;
  string url1;
  string url2;
  
  bytes32 public addrStr;

  /**  
  * @dev Details of each transfer  
  * @param contract_ contract address of ER20 token to transfer  
  * @param to_ receiving account  
  * @param amount_ number of tokens to transfer to_ account  
  * @param failed_ if transfer was successful or not  
  */  
  struct Transfer {  
    address contract_;  
    address to_;  
    uint amount_;  
    bool failed_;  
  }
  
  event requestBountyCompleteFulfilled(
    bytes32 indexed requestId,
    bytes32 indexed addrStr
  );

  /**  
  * @dev a mapping from transaction ID's to the sender address  
  * that initiates them. Owners can create several transactions  
  */  
  mapping(address => uint[]) public transactionIndexesToSender;
  /**  
  * @dev a list of all transfers successful or unsuccessful  
  */  

  address public owner;  
  
  /**  
  * @dev list of all supported tokens for transfer  
  * @param string token symbol  
  * @param address contract address of token  
  */  
  mapping(bytes32 => address) public tokens; 

  ERC20 public ERC20Interface;

  Transfer[] public transactions;

  /**  
  * @dev Event to notify if transfer successful or failed  
  * after account approval verified  
  */  
  event TransferSuccessful(address indexed from_, address indexed to_, uint256 amount_);  
  
  event TransferFailed(address indexed from_, address indexed to_, uint256 amount_);

  /**  
  * @dev add address of token to list of supported tokens using  
  * token symbol as identifier in mapping  
  */  
  function addNewToken(bytes32 symbol_, address address_) public onlyOwner returns (bool) {  
    tokens[symbol_] = address_;  
    
    return true;  
  }  
    
  /**  
  * @dev remove address of token we no more support  
  */  
  function removeToken(bytes32 symbol_) public onlyOwner returns (bool) {  
    require(tokens[symbol_] != 0x0);  
  
    delete(tokens[symbol_]);  
    
    return true;  
  }  
    
  /**  
  * @dev method that handles transfer of ERC20 tokens to other address  
  * it assumes the calling address has approved this contract  
  * as spender  
  * @param symbol_ identifier mapping to a token contract address  
  * @param to_ beneficiary address  
  * @param amount_ numbers of token to transfer  
  */  
  function transferTokens(bytes32 symbol_, address to_, uint256 amount_) public {  
    require(tokens[symbol_] != 0x0);  
    require(amount_ > 0);  
    
    address contract_ = tokens[symbol_];  
    address from_ = msg.sender;  
  
    ERC20Interface = ERC20(contract_);  
    
    uint256 transactionId = transactions.push(  
    Transfer({  
    contract_:  contract_,  
          to_: to_,  
          amount_: amount_,  
          failed_: true  
    })  
  );  
    transactionIndexesToSender[from_].push(transactionId - 1);  
    
    if(amount_ > ERC20Interface.allowance(from_, address(this))) {  
    emit TransferFailed(from_, to_, amount_);  
    revert();  
  }  
    ERC20Interface.transferFrom(from_, to_, amount_);  
    
    transactions[transactionId - 1].failed_ = false;  
    
    emit TransferSuccessful(from_, to_, amount_);  
  }  
    
  /**  
  * @dev withdraw funds from this contract  
  * @param beneficiary address to receive ether  
  */  
  function withdraw(address beneficiary) public payable onlyOwner {  
    beneficiary.transfer(address(this).balance);  
  }
  
  function cashReward(bytes32 symbol_, address to_, uint256 amount_) public {
      require(tokens[symbol_] != 0x0);  
      require(amount_ > 0);  
    
      address contract_ = tokens[symbol_]; 
      
      ERC20Interface = ERC20(contract_);  
    
      uint256 transactionId = transactions.push(  
      Transfer({  
      contract_:  contract_,  
          to_: to_,  
          amount_: amount_,  
          failed_: true  
      })  
    );  
    
    if(amount_ > ERC20Interface.balanceOf(address(this))) {  
      emit TransferFailed(address(this), to_, amount_);  
      revert();  
    } 
      
      ERC20Interface.transferFrom(address(this), to_, amount_);  
      
      transactions[transactionId - 1].failed_ = false;  
    
      emit TransferSuccessful(address(this), to_, amount_);  
  }

  uint256 reward_pool;
  
  struct Bounty {
      uint id;
      string repo_link;
      string tag;
      uint reward_amount;
      bool active;
      string title;
      string description;
  }
  
  struct Meister {
      address id;
      uint bounties_fulfilled;
  }
  
  uint[] public bountyIDs;
  address[] public allMeisters;
  
  mapping (address => uint[]) public meister_bounty_ids;
  mapping (string => uint[]) private repo_bounties;
  mapping (uint => Bounty) public bounties;
  
  event NewBounty(uint _bounty_id, address _owner, uint _reward);

  constructor() public Ownable() {
    setPublicChainlinkToken();
    _oracle = address(0x56dd6586DB0D08c6Ce7B2f2805af28616E082455);
    _jobId = "c128fbb0175442c8ba828040fdd1a25e";
    bytes32 b = stringToBytes32("DAI");
    addNewToken(b, address(0x4dC966317B2c55105FAd4835F651022aCD632120));
    url1 = "https://api.github.com/repos/";
    url2 = "/pulls/";
  }
  
  function AddNewMeister() private {
      allMeisters.push(msg.sender);
  }
  
  function CreateBounty(string memory repoLink, 
                        uint reward, 
                        string PR_tag,
                        string title,
                        string description) public returns (uint bountyID) {
      Bounty memory bounty = Bounty({
          id: bountyIDs.length,
          repo_link: repoLink,
          tag: PR_tag,
          reward_amount: reward,
          active: true,
          title: title,
          description: description
      }); 

      uint len = repo_bounties[repoLink].length;

      if(len != 0) {
        for(uint i = 0; i < len; i++) {
          uint id = repo_bounties[repoLink][i];

          require(compare(bounties[id].tag, PR_tag) != 0 || !bounties[id].active);
        }
      }

      repo_bounties[repoLink].push(bounty.id);

      if (meister_bounty_ids[msg.sender].length == 0) {
          AddNewMeister();
      }

      meister_bounty_ids[msg.sender].push(bounty.id);
      bountyIDs.push(bounty.id);
      bounties[bounty.id] = bounty;
      return bounty.id;
  }
  
  function GetMeisterBounties(address meister) public view returns (uint[] memory bountyIds) {
      return meister_bounty_ids[meister];
  }

  function GetRepoBounties(string repoLink) public view returns (uint[] memory bountyIds) {
      return repo_bounties[repoLink];
  }
  
  function GetBountyInfo(uint bountyId) public view returns (uint id, 
                                                        string memory repoLink, 
                                                        string memory tag, 
                                                        uint reward, 
                                                        bool active,
                                                        string memory title,
                                                        string memory description) {
      Bounty memory bounty = bounties[bountyId];
      return (bounty.id, 
              bounty.repo_link, 
              bounty.tag, 
              bounty.reward_amount, 
              bounty.active,
              bounty.title,
              bounty.description);
  }
  

  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }

  function compare(string _a, string _b) private pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    
    function requestBountyComplete(string repo_link, string PR_id)
    public
    onlyOwner
    {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillBountyComplete.selector);
        req.add("get", string(abi.encodePacked(url1, repo_link, url2, PR_id)));
        req.add("path", "body");
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }
  
    function fulfillBountyComplete(bytes32 _requestId, bytes32 _addrStr)
    public
    recordChainlinkFulfillment(_requestId)
    {
        emit requestBountyCompleteFulfilled(_requestId, _addrStr);
        addrStr = _addrStr;
    }

}
