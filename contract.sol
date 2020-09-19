pragma solidity >=0.6.0 <0.7.0;

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/vendor/Ownable.sol";

contract JagerGitClient is ChainlinkClient, Ownable {
  uint256 reward_pool;
  
  struct Bounty {
      uint id;
      string repo_link;
      string random_key;
      uint reward_amount;
      bool active;
  }
  
  struct Meister {
      address id;
      uint bounties_fulfilled;
  }
  
  Bounty[] public allBounties;
  address[] public allMeisters;
  
  mapping (address => uint[]) public meister_bounty_ids;
  mapping (uint => Bounty) public bounties;
  
  event NewBounty(uint _bounty_id, address _owner, uint _reward);

  constructor() public {
    setPublicChainlinkToken();
  }
  
  function AddNewMeister(address meisterAddress) public onlyOwner {
      allMeisters.push(meisterAddress);
  }
  
  function CreateBounty(address meisterAddress, string memory repoLink, uint reward) public onlyOwner {
      Bounty memory bounty = Bounty({
          id: 1,
          repo_link: repoLink,
          random_key: "JAG",
          reward_amount: reward,
          active: true
      });

      if (meister_bounty_ids[meisterAddress].length == 0) {
          AddNewMeister(meisterAddress);
      }
      meister_bounty_ids[meisterAddress].push(bounty.id);
  }
  
  function GetUsers() public returns (address[] memory users) {
      return allMeisters;
  }
  
  function GetMeisterBounties(address meister) public returns (uint[] memory bountyIds) {
      return meister_bounty_ids[meister];
  }
  
  function GetBountyInfo(uint bountyId) public returns (uint id, string memory repoLink, string memory prKey, uint reward, bool active) {
      Bounty memory bounty = allBounties[bountyId];
      return (bounty.id, bounty.repo_link, bounty.random_key, bounty.reward_amount, bounty.active);
  }

}