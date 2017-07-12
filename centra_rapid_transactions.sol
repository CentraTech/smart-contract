// ----------------------------------------------------------------------------------------------
   // Developer Nechesov Andrey
   // Enjoy. (c) PRCR.org ICO Platform 2017. The PRCR Licence.
   // ----------------------------------------------------------------------------------------------    
   
  pragma solidity ^0.4.11;
  //0x8891d8c0e99625e048e9f1befaebc3e2d0390492
  
  contract TxRapidInterface {         
   
      // Get the account balance of another account with address _owner
      function balanceOf(address _owner) constant returns (uint256 balance);

      //User add money from own address to contract address
      function money_add() payable returns(bool result);

      //User request money from contract address to own address
      function request_withdraw(uint256 _value) returns(bool result);      

      // Send _value amount of money from address _from to address _to
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
      
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
      event Request_event(address indexed _address, uint _amount, uint _status);     
  }

  contract TxRapid is TxRapidInterface {

      address public owner;

      // Balances for each account
      mapping(address => uint256) balances;            

      struct Request {
        address _address;
        uint _amount;    
        uint _time;    
      }   

      // Requests withdraw money
      Request[] public requests;      
      uint public min_amount_request = 10**15;
      uint public requests_step_check = 50;
      uint public requests_count_next = 0;            

      mapping(address => uint) public requests_info; 

      mapping(address => mapping (address => uint256)) allowed; 

      // Constructor
      function TxRapid() {
          owner = msg.sender;          
      }      

      //User add money from own address to contract address
      function money_add() payable returns(bool result) {

         if(!(msg.value>0)) throw;
         balances[msg.sender] += msg.value;         
         return true;
      }

      //User request money from contract address to own address
      function request_withdraw(uint256 _value) returns(bool result) {
         if(!(_value >= min_amount_request)) false;         
         if(balances[msg.sender] < _value) false;
         requests.push(Request(msg.sender, _value, now));  
         Request_event(msg.sender, _value, 0);
         requests_info[msg.sender] += _value;       

      } 

      function requests_total() constant returns (uint total) {
         return requests.length;
      }     

      // What is the balance of a particular account?
      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }

    // Send _value amount of money from contract address _from to contract address _to
    
    function transferFrom (
        address _from,
        address _to,
        uint256 _amount
      ) onlyOwner returns (bool success) {         

       if (balances[_from] >= _amount
           //&& allowed[_from][msg.sender] >= _amount
           && _amount > 0
           && balances[_to] + _amount > balances[_to]) {
           balances[_from] -= _amount;
           //allowed[_from][msg.sender] -= _amount;
           balances[_to] += _amount;
           Transfer(_from, _to, _amount);
           return true;
       } else {
           return false;
       }
    }   

    //Check requests and if ok send money [_to] account
    //Withdraw money from [_from] contract address to [_to] account
    function requests_check() onlyOwner returns(bool results) {

       uint requests_count_finish = requests.length;

       if(requests.length >= requests_count_next + requests_step_check){
          requests_count_finish = requests_count_next + requests_step_check;
       }

       for (uint i = requests_count_next; i < requests_count_finish; i++) {

          if(balances[requests[i]._address] >= requests[i]._amount) {
             if(request_withdraw_send(requests[i]._address, requests[i]._amount)) {
                balances[requests[i]._address] -= requests[i]._amount;  
                requests_info[requests[i]._address] -= requests[i]._amount;                                   
                Request_event(requests[i]._address, requests[i]._amount, 1);
             }               
          }else{
                Request_event(requests[i]._address, requests[i]._amount, 2);
          }

       }

       requests_count_next = requests_count_finish;
    }
      

    //Withdraw money from [_from] contract address to [_to] account
    function request_withdraw_send(
             address _address,
             uint _amount
          ) onlyOwner private returns (bool result) {
        if(!(balances[_address] >= _amount)) return false;        
        balances[_address] -= balances[_address];
        _address.send(_amount);
        return true;
    }  
      

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }  

  }

  /**
   * Math operations with safety checks
   */
  library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint a, uint b) internal returns (uint) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c >= a);
      return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a < b ? a : b;
    }

    function assert(bool assertion) internal {
      if (!assertion) {
        throw;
      }
    }
  }