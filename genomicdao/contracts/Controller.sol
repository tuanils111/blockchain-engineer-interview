pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./NFT.sol";
import "./Token.sol";

contract Controller {
    using Counters for Counters.Counter;

    //
    // STATE VARIABLES
    //
    Counters.Counter private _sessionIdCounter;
    GeneNFT public geneNFT;
    PostCovidStrokePrevention public pcspToken;

    struct UploadSession {
        uint256 id;
        address user;
        string proof;
        bool confirmed;
    }

    struct DataDoc {
        string id;
        string hashContent;
    }

    mapping(uint256 => UploadSession) sessions;
    mapping(string => DataDoc) docs;
    mapping(string => bool) docSubmits;
    mapping(uint256 => string) nftDocs;

    //
    // EVENTS
    //
    event UploadData(string docId, uint256 sessionId);

    constructor(address nftAddress, address pcspAddress) {
        geneNFT = GeneNFT(nftAddress);
        pcspToken = PostCovidStrokePrevention(pcspAddress);
    }

    function uploadData(string memory docId) public returns (uint256) {
        // TODO: Implement this method: to start an uploading gene data session. The doc id is used to identify a unique gene profile. Also should check if the doc id has been submited to the system before. This method return the session id
        if (bytes(docs[docId].id).length > 0) {
            revert("Doc already been submitted");
        }
        docs[docId] = DataDoc(docId, "");
        uint256 sessionId = _sessionIdCounter.current();
        _sessionIdCounter.increment();
        sessions[sessionId] = UploadSession(sessionId, msg.sender, "", false);
        emit UploadData(docId, sessionId);
        return sessionId;
    }

    function confirm(
        string memory docId,
        string memory contentHash,
        string memory proof,
        uint256 sessionId,
        uint256 riskScore
    ) public {
        // TODO: Implement this method: The proof here is used to verify that the result is returned from a valid computation on the gene data. For simplicity, we will skip the proof verification in this implementation. The gene data's owner will receive a NFT as a ownership certicate for his/her gene profile.

        DataDoc storage doc = docs[docId];
        UploadSession storage session = sessions[sessionId];

        // confirm upload
        if (bytes(doc.id).length > 0 && session.confirmed == true) {
            revert("Doc already been submitted");
        } 
        if (session.user != msg.sender) {
            revert("Invalid session owner");
        } 
        if (bytes(doc.id).length <= 0 && session.confirmed == true) {
            revert("Session is ended");
        }
        // TODO: Verify proof, we can skip this step
        session.proof = proof;

        // TODO: Update doc content
        doc.hashContent = contentHash;

        // TODO: Mint NFT 
        geneNFT.safeMint(msg.sender);

        // TODO: Reward PCSP token based on risk stroke
        pcspToken.reward(msg.sender, riskScore);

        // TODO: Close session
        session.confirmed = true;
    }

    function getSession(uint256 sessionId) public view returns(UploadSession memory) {
        return sessions[sessionId];
    }

    function getDoc(string memory docId) public view returns(DataDoc memory) {
        return docs[docId];
    }
}
