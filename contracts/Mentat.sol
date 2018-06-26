pragma solidity ^0.4.23;

//import './MentatToken.sol';

contract Mentat {

    /////
    // Storage
    ///////////////////////////////

    address public owner;  // contract´s creator
    address public mentatToken;
    enum SkillType {Skill, Expertise}
    enum TaskStatus {
        Opened, // waiting for a payment
        Paid, // buyer should pay right after the opening
        Matched, // agent is matched for the task
        Accepted, // // agent accepted the task
        Rejected, // after N rejections
        Completed, // agent answered
        Reviewed // the third review is done
    }
    enum ChatMessageOwner {Agent, Buyer}

    struct Skill {
        string name;
        SkillType skill;
        mapping(uint => address) agents;
        uint agentsCount;
    }

    mapping(uint => Skill) public skills;
    uint public skillsCount;

    struct Agent {
        string name;
        string email;
        bool isBusy;
        mapping(uint => AgentSkill) agentSkills;
        uint agentSkillsCount;
        uint registrationTimestamp; // DateTime
        uint lastActionTimestamp; //DateTime
        uint tasksCompleted;
        uint tasksRejected;
        uint agentsReviews;
        uint currentTaskId;
        bool currentTaskType; // 1 - task, 0 - review
    }

    mapping(address => Agent) public agents;

    struct AgentSkill {
        uint skillID;
        uint experience;
        uint level;
    }

    struct TaskBundle1 {
        uint applicationID;
        address agent;
        address buyer;
        uint skillID;
        uint skillLevel;
        uint skillLevelMultiplier;
        bytes32 request;
        bytes32 response;
        string description;
        TaskStatus status;
        mapping(uint => address) rejectedAgents;
        uint rejectedAgentsCount;
        uint createdTimestamp;  //DateTime
        uint lastUpdateTimestamp; //DateTime
    }

    struct TaskBundle2 {
        address reviewAgent1;
        address reviewAgent2;
        address reviewAgent3;
        bool reviewResult1;
        bool reviewResult2;
        bool reviewResult3;
        uint expectedPrice;
        uint price;
        uint tokensAmount;
        bool withdrawn;
        bool tokensWithdrawn;
        uint expectedCompleteTime;  //DateTime
        uint completeTime;  //DateTime
    }

    mapping(uint => TaskBundle1) public tasksBundle1;
    mapping(uint => TaskBundle2) public tasksBundle2;
    uint public tasksCount;

    struct Application {
        string name;
    }

    mapping(uint => Application) public applications;
    uint public applicationsCount;

    ////
    // Events
    ///////////////

    event SUCCESS(string message);
    event FAIL(string message);

    ////
    // Modifiers
    ///////////////

    modifier checkAgentRegistered(address _address) {
        require(agents[_address].registrationTimestamp > 0);
        _;
    }

    modifier isNotAgentRegistered(address _address) {
        require(agents[_address].registrationTimestamp == 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMentatToken() {
        require(msg.sender == mentatToken);
        _;
    }

    ////
    // Public methods
    ///////////////

    constructor() public {
        owner = msg.sender;
    }

    function setMentatToken(address newMentatToken)
    onlyOwner
    public {
        mentatToken = newMentatToken;
    }

    function agentSignIn()
    checkAgentRegistered(msg.sender)
    public {
        agentUpdateOnline(msg.sender);
        emit SUCCESS("signedIn");
    }

    function agentSignOut()
    checkAgentRegistered(msg.sender)
    public {
        agents[msg.sender].lastActionTimestamp = 0;
        emit SUCCESS("signedOut");
    }

    function agentSignUp(string _name, string _email)
    isNotAgentRegistered(msg.sender)
    public {
        agents[msg.sender] = Agent({
            name : _name,
            email : _email,
            isBusy : false,
            agentSkillsCount : 0,
            registrationTimestamp : now,
            lastActionTimestamp : now,
            tasksCompleted : 0,
            tasksRejected : 0,
            agentsReviews : 0,
            currentTaskId : 0,
            currentTaskType : false
            });
        emit SUCCESS("signedUp");
    }

    function isAgentRegistered(address agent) public view
    checkAgentRegistered(agent)
    returns (bool)
    {
        return true;
    }

    function isAgentOnline(address agent) public view
    checkAgentRegistered(agent)
    returns (bool) {
        return ((now - agents[agent].lastActionTimestamp) < 1 hours);
    }

    function agentUpdateAccount(string _name, string _email)
    checkAgentRegistered(msg.sender)
    public {
        agents[msg.sender].name = _name;
        agents[msg.sender].email = _email;
        agentUpdateOnline(msg.sender);
        emit SUCCESS("agentAccountUpdated");
    }

    function agentStartReview(uint _taskID) public 
    checkAgentRegistered(msg.sender)
    returns (bool) {
        require(!agentIsBusy(msg.sender));
        agents[msg.sender].isBusy = true;
        agents[msg.sender].currentTaskId = _taskID;
        agents[msg.sender].currentTaskType = false;
        if (tasksBundle2[_taskID].reviewAgent1 != address(0)) {
            if(tasksBundle2[_taskID].reviewAgent2 != address(0)) {
                if(tasksBundle2[_taskID].reviewAgent3 != address(0)) {
                    return false;
                } else {
                    tasksBundle2[_taskID].reviewAgent3 = msg.sender;
                }   
            } else {
                tasksBundle2[_taskID].reviewAgent2 = msg.sender;
            }
        } else {
            tasksBundle2[_taskID].reviewAgent1 = msg.sender;
        }
        tasksBundle1[_taskID].lastUpdateTimestamp = now;
        agentUpdateOnline(msg.sender);
        emit SUCCESS("agentReviewStarted");
    }
    
    function agentFinishReview(uint _taskID, bool _result) public 
    checkAgentRegistered(msg.sender)
    returns (bool) {
        agents[msg.sender].isBusy = false;
        agents[msg.sender].agentsReviews++;
        agents[msg.sender].currentTaskId = 0;
        if (tasksBundle2[_taskID].reviewAgent1 != msg.sender) {
            if(tasksBundle2[_taskID].reviewAgent2 != msg.sender) {
                if(tasksBundle2[_taskID].reviewAgent3 != msg.sender) {
                    return false;
                } else {
                    tasksBundle2[_taskID].reviewResult3 = _result;
                }   
            } else {
                tasksBundle2[_taskID].reviewResult2 = _result;
            }
        } else {
            tasksBundle2[_taskID].reviewResult1 = _result;
        }
        tasksBundle1[_taskID].lastUpdateTimestamp = now;
        tasksBundle1[_taskID].status = TaskStatus.Reviewed;
        agentUpdateOnline(msg.sender);
        emit SUCCESS("agentReviewFinished");
    }    

    function getTaskPrice(uint _taskID) public view  
    returns (uint)  {
        return tasksBundle2[_taskID].price;
    }
    
    function agentGetCurrentTaskType() public view
    checkAgentRegistered(msg.sender)
    returns (bool) {
        return agents[msg.sender].currentTaskType;
    }
    
    function changeAgent(uint _taskID) public
    checkAgentRegistered(msg.sender) {
        agents[msg.sender].isBusy = true;
        agents[msg.sender].lastActionTimestamp = now;
        agents[msg.sender].currentTaskId = _taskID;
        agents[msg.sender].currentTaskType = true;   
        tasksBundle1[_taskID].agent = msg.sender;
        tasksBundle1[_taskID].status = TaskStatus.Matched;
        tasksBundle1[_taskID].lastUpdateTimestamp;
    }

    function agentGetCurrentTask() public view
    checkAgentRegistered(msg.sender)
    returns (uint taskId, bool taskType, string applicationName, string description) {
        taskType = agents[msg.sender].currentTaskType;
        taskId = agents[msg.sender].currentTaskId;
        require(taskId > 0);
        uint applicationId = tasksBundle1[taskId].applicationID;
        applicationName = applications[applicationId].name;
        description = tasksBundle1[taskId].description;
        return;
    }

    function acceptTask(uint taskId, address agent, uint tokensAmount)
    onlyMentatToken
    public {
        tasksBundle1[taskId].status = TaskStatus.Accepted;
        tasksBundle2[taskId].tokensAmount = tokensAmount;
        agentUpdateOnline(agent);
    }


    ////
    // Internal methods
    ///////////////
    function agentUpdateOnline(address agent)
    internal
    {
        agents[agent].lastActionTimestamp = now;
    }

    function agentIsBusy(address agent) view
    internal
    returns (bool)
    {
        return(agents[agent].isBusy);
    }

}
