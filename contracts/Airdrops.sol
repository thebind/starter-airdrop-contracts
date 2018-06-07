pragma solidity ^0.4.16;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  function Owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
     c = a - b;
   }
   function mul(uint a, uint b) internal pure returns (uint c) {
     c = a * b;
     require(a == 0 || c / a == b);
   }
   function div(uint a, uint b) internal pure returns (uint c) {
     require(b > 0);
     c = a / b;
   }
 }

contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract FixedSupplyToken is ERC20Interface, Owned {
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalSupply;
  address public msgsender;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;


  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  function FixedSupplyToken() public {
    symbol = "PELICA";
    name = "Fixed Supply Token";
    decimals = 18;
    _totalSupply = 1000000 * 10**uint(decimals);
    balances[owner] = _totalSupply;
    Transfer(address(0), owner, _totalSupply);
  }


  // ------------------------------------------------------------------------
  // Total supply
  // ------------------------------------------------------------------------
  function totalSupply() public constant returns (uint) {
    return _totalSupply  - balances[address(0)];
  }


  // ------------------------------------------------------------------------
  // Get the token balance for account `tokenOwner`
  // ------------------------------------------------------------------------
  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }


  // ------------------------------------------------------------------------
  // Transfer the balance from token owner's account to `to` account
  // - Owner's account must have sufficient balance to transfer
  // - 0 value transfers are allowed
  // ------------------------------------------------------------------------
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(msg.sender, to, tokens);
    return true;
  }


  // ------------------------------------------------------------------------
  // Token owner can approve for `spender` to transferFrom(...) `tokens`
  // from the token owner's account
  //
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
  // recommends that there are no checks for the approval double-spend attack
  // as this should be implemented in user interfaces
  // ------------------------------------------------------------------------
  function approve(address spender, uint tokens) public returns (bool success) {
      msgsender = msg.sender;
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    return true;
  }


  // ------------------------------------------------------------------------
  // Transfer `tokens` from the `from` account to the `to` account
  //
  // The calling account must already have sufficient tokens approve(...)-d
  // for spending from the `from` account and
  // - From account must have sufficient balance to transfer
  // - Spender must have sufficient allowance to transfer
  // - 0 value transfers are allowed
  // ------------------------------------------------------------------------
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      msgsender = msg.sender;
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(from, to, tokens);
    return true;
  }


  // ------------------------------------------------------------------------
  // Returns the amount of tokens approved by the owner that can be
  // transferred to the spender's account
  // ------------------------------------------------------------------------
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }


  // ------------------------------------------------------------------------
  // Token owner can approve for `spender` to transferFrom(...) `tokens`
  // from the token owner's account. The `spender` contract function
  // `receiveApproval(...)` is then executed
  // ------------------------------------------------------------------------
  function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
    return true;
  }


  // ------------------------------------------------------------------------
  // Don't accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }


  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}


contract AirdropFactory {
    address[] public deployedAirdrops;

    function createAirdrop(address addressOfToken, string tokenName) public {
        address newAirdrop = new Broadcast(addressOfToken, tokenName, msg.sender);
        deployedAirdrops.push(newAirdrop);
    }

    function getDeployedAirdrops() public view returns (address[]) {
        return deployedAirdrops;
    }

}


/*
 * Token Standard
 * https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 */
interface ERC20TokenInterface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) payable public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Broadcast {
    /*
    struct List{
        address receiver;
        uint256 value;
    }
    */
    ERC20TokenInterface public tokenInterface;
    address public tokenAddress;
    string public tokenName;
    address public manager;
    //mapping(address => uint256) public balanceOf;


    modifier restricted() {
        require(msg.sender == manager);
        _;
    }


    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Broadcast(address addressOfToken, string name, address creator) public {
        manager = creator;
        tokenName = name;
        tokenInterface = ERC20TokenInterface(addressOfToken);
        tokenAddress = addressOfToken;
    }

    /**
     * CheckTokenBalance
     */
    function tokenBalanceOf(address tokenOwner) public constant returns (uint balance) {
        return tokenInterface.balanceOf(tokenOwner);
    }

    function contractAddress() public constant returns (address ca) {
        return this;
    }


    function transferTokenFrom(address from, address to, uint tokens) public restricted returns (bool success) {
      tokenInterface.transferFrom(from, to, tokens);
      return true;
    }


    /**
     * Dispatch Token which is listed
     *
     */
    function dispatchTokenFrom(address from, address[] receiver, uint256[] value) public restricted{
        for (uint i = 0; i < receiver.length; i++) {
            tokenInterface.transferFrom(from, receiver[i], value[i]);
        }
    }


    function allowanceToken(address tokenOwner, address spender) public constant returns (uint remaining){
        return tokenInterface.allowance(tokenOwner, spender);
    }

    /**
     * DO NOT ACCEPT ETH
     */
    function () payable public {
        revert();
    }


    function getSummary() public view returns (
        string, address, address, address, uint
        ) {
        return (
            tokenName,
            tokenAddress,
            manager,
            this,
            tokenBalanceOf(this)
        );
    }


}
