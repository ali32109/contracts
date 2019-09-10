pragma solidity ^0.5.2;
import { RLPReader } from "solidity-rlp/contracts/RLPReader.sol";
// import { Ownable } from "openzeppelin-solidity/contracts/ownership/Ownable.sol";
// import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { StakeManager } from "./StakeManager.sol";
// import { Registry } from "../common/Registry.sol";
// import { IStakeManager } from "./IStakeManager.sol";
import { ECVerify } from "../common/lib/ECVerify.sol";
import { Registry } from "../common/Registry.sol";

contract Slashing {
  using ECVerify for bytes32;
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  uint256 checkpointHaltEpoch = 0;
  uint256 haltInterval = 50; // epoch
  uint256 slashingRate = 5; // slashing %
  Registry registry;
  // event validator(address indexed signer);

  constructor (address _registry) public {
    registry = Registry(_registry);
  }

  function doubleSign(bytes memory vote1, bytes memory vote2, bytes memory sig1, bytes memory sig2) public {
    // Todo: fix signer chanage for same validator
    RLPReader.RLPItem[] memory dataList1 = vote1.toRlpItem().toList();
    RLPReader.RLPItem[] memory dataList2 = vote2.toRlpItem().toList();

    bytes32 chain = keccak256("test-chain-E5igIA");
    bytes32 roundType = keccak256("vote");
    uint8 voteType = 2;

    require(dataList1[2].toUint() == dataList2[2].toUint(), "sig isn't duplicate");
    require((keccak256(dataList1[0].toBytes()) == chain && keccak256(dataList2[0].toBytes()) == chain),"Chain ID not same");
    require((keccak256(dataList1[1].toBytes()) == roundType && keccak256(dataList2[1].toBytes()) == roundType), "Round type not same ");
    require((dataList1[3].toUint() == voteType && dataList2[3].toUint() == voteType), "Vote type not same");
    require(keccak256(dataList1[4].toBytes()) != keccak256(dataList2[4].toBytes()), "same vote");

    address signer = keccak256(vote1).ecrecovery(sig1);
    require(signer == keccak256(vote2).ecrecovery(sig2));
    // emit validator(signer);
    StakeManager stakeManager = StakeManager(registry.getStakeManagerAddress());
    uint256 validatorId = stakeManager.signerToValidator(signer);
    stakeManager.slash(validatorId, slashingRate);
  }

  function checkpointHalt(uint256 start) public {

  }

}