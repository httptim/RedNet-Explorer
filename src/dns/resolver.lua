-- DNS Conflict Resolver Module for RedNet-Explorer
-- Handles domain disputes and conflict resolution using consensus

local resolver = {}

-- Load dependencies
local protocol = require("src.common.protocol")
local discovery = require("src.common.discovery")

-- Configuration
resolver.CONFIG = {
    -- Consensus settings
    minVoters = 3,                -- Minimum peers to form consensus
    votingTimeout = 30,           -- Time to collect votes in seconds
    majorityThreshold = 0.66,     -- 66% agreement needed
    
    -- Dispute settings
    disputeTimeout = 300,         -- 5 minutes to resolve dispute
    maxDisputesPerHour = 5,       -- Rate limiting
    blacklistDuration = 3600,     -- 1 hour blacklist for abuse
    
    -- Trust settings
    trustDecayRate = 0.1,         -- Trust decay per dispute
    minTrustLevel = 0.1,          -- Minimum trust before blacklist
    initialTrust = 1.0            -- Starting trust level
}

-- Active disputes and resolutions
local activeDisputes = {}
local resolvedDisputes = {}
local peerTrust = {}
local blacklist = {}

-- Initialize resolver
function resolver.init()
    -- Don't start dispute handler here - it should be started
    -- in parallel by the caller
    
    return true
end

-- Raise a domain dispute
function resolver.raiseDispute(domain, claimedOwner, evidence)
    if type(domain) ~= "string" then
        return false, "Invalid domain"
    end
    
    -- Check if already disputed
    if activeDisputes[domain] then
        return false, "Dispute already active for this domain"
    end
    
    -- Check rate limiting
    if resolver.isRateLimited(os.getComputerID()) then
        return false, "Too many disputes raised"
    end
    
    -- Create dispute record
    local dispute = {
        id = string.format("%s-%d-%d", domain, os.getComputerID(), os.epoch("utc")),
        domain = domain,
        claimant = os.getComputerID(),
        claimed = claimedOwner,
        evidence = evidence or {},
        raised = os.epoch("utc"),
        expires = os.epoch("utc") + (resolver.CONFIG.disputeTimeout * 1000),
        votes = {},
        status = "voting"
    }
    
    activeDisputes[domain] = dispute
    
    -- Broadcast dispute to network
    resolver.broadcastDispute(dispute)
    
    -- Start voting process
    resolver.startVoting(dispute)
    
    return true, dispute.id
end

-- Broadcast dispute to network
function resolver.broadcastDispute(dispute)
    local message = protocol.createMessage(
        "DISPUTE_RAISED",
        {
            dispute = dispute,
            timestamp = os.epoch("utc")
        }
    )
    
    protocol.broadcastMessage(message, protocol.PROTOCOLS.DNS)
end

-- Start voting process for dispute
function resolver.startVoting(dispute)
    -- Request votes from trusted peers
    local peers = discovery.getPeersByType(discovery.PEER_TYPES.SERVER)
    
    for _, peer in ipairs(peers) do
        if resolver.getTrustLevel(peer.id) > resolver.CONFIG.minTrustLevel then
            local request = protocol.createMessage(
                "VOTE_REQUEST",
                {
                    disputeId = dispute.id,
                    domain = dispute.domain,
                    claimant = dispute.claimant,
                    claimed = dispute.claimed,
                    evidence = dispute.evidence
                }
            )
            
            protocol.sendMessage(peer.id, request, protocol.PROTOCOLS.DNS)
        end
    end
    
    -- Set timer for vote collection
    local function collectVotes()
        sleep(resolver.CONFIG.votingTimeout)
        resolver.tallyVotes(dispute)
    end
    
    parallel.waitForAny(collectVotes)
end

-- Handle incoming vote
function resolver.handleVote(message, senderId)
    local disputeId = message.data.disputeId
    local vote = message.data.vote
    
    -- Find dispute
    local dispute = nil
    for domain, d in pairs(activeDisputes) do
        if d.id == disputeId then
            dispute = d
            break
        end
    end
    
    if not dispute then
        return false, "Dispute not found"
    end
    
    -- Check if voting is still open
    if dispute.status ~= "voting" then
        return false, "Voting closed"
    end
    
    -- Check voter trust
    if resolver.getTrustLevel(senderId) <= resolver.CONFIG.minTrustLevel then
        return false, "Voter not trusted"
    end
    
    -- Record vote
    dispute.votes[senderId] = {
        vote = vote, -- "claimant", "claimed", or "abstain"
        timestamp = os.epoch("utc"),
        trust = resolver.getTrustLevel(senderId)
    }
    
    return true
end

-- Tally votes and resolve dispute
function resolver.tallyVotes(dispute)
    if dispute.status ~= "voting" then
        return
    end
    
    dispute.status = "tallying"
    
    -- Count votes weighted by trust
    local claimantVotes = 0
    local claimedVotes = 0
    local totalWeight = 0
    
    for voterId, vote in pairs(dispute.votes) do
        local weight = vote.trust
        totalWeight = totalWeight + weight
        
        if vote.vote == "claimant" then
            claimantVotes = claimantVotes + weight
        elseif vote.vote == "claimed" then
            claimedVotes = claimedVotes + weight
        end
    end
    
    -- Check if we have enough votes
    local voterCount = 0
    for _ in pairs(dispute.votes) do
        voterCount = voterCount + 1
    end
    
    if voterCount < resolver.CONFIG.minVoters then
        dispute.status = "insufficient_votes"
        dispute.resolution = "No consensus - insufficient voters"
        resolver.finalizeDispute(dispute)
        return
    end
    
    -- Determine winner
    local claimantRatio = claimantVotes / totalWeight
    local claimedRatio = claimedVotes / totalWeight
    
    if claimantRatio > resolver.CONFIG.majorityThreshold then
        dispute.winner = dispute.claimant
        dispute.resolution = "Claimant wins by consensus"
    elseif claimedRatio > resolver.CONFIG.majorityThreshold then
        dispute.winner = dispute.claimed
        dispute.resolution = "Current owner retains domain"
    else
        dispute.winner = nil
        dispute.resolution = "No clear consensus"
    end
    
    dispute.status = "resolved"
    
    -- Update trust levels based on voting pattern
    resolver.updateTrust(dispute)
    
    -- Finalize dispute
    resolver.finalizeDispute(dispute)
end

-- Finalize dispute resolution
function resolver.finalizeDispute(dispute)
    -- Move to resolved disputes
    activeDisputes[dispute.domain] = nil
    resolvedDisputes[dispute.id] = dispute
    
    -- Broadcast resolution
    local message = protocol.createMessage(
        "DISPUTE_RESOLVED",
        {
            disputeId = dispute.id,
            domain = dispute.domain,
            winner = dispute.winner,
            resolution = dispute.resolution,
            timestamp = os.epoch("utc")
        }
    )
    
    protocol.broadcastMessage(message, protocol.PROTOCOLS.DNS)
    
    -- If ownership changed, update DNS
    if dispute.winner and dispute.winner ~= dispute.claimed then
        -- Force DNS update
        local update = protocol.createMessage(
            "DNS_UPDATE",
            {
                domain = dispute.domain,
                owner = dispute.winner,
                reason = "Dispute resolution"
            }
        )
        
        protocol.broadcastMessage(update, protocol.PROTOCOLS.DNS)
    end
end

-- Update trust levels based on voting
function resolver.updateTrust(dispute)
    if not dispute.winner then
        return
    end
    
    -- Reduce trust for the loser if they were found to be wrong
    local loser = dispute.winner == dispute.claimant and dispute.claimed or dispute.claimant
    resolver.adjustTrust(loser, -resolver.CONFIG.trustDecayRate)
    
    -- Check for blacklisting
    if resolver.getTrustLevel(loser) <= resolver.CONFIG.minTrustLevel then
        resolver.blacklistPeer(loser)
    end
end

-- Get trust level for a peer
function resolver.getTrustLevel(peerId)
    if blacklist[peerId] then
        return 0
    end
    
    return peerTrust[peerId] or resolver.CONFIG.initialTrust
end

-- Adjust trust level
function resolver.adjustTrust(peerId, adjustment)
    local current = resolver.getTrustLevel(peerId)
    local new = math.max(0, math.min(1, current + adjustment))
    peerTrust[peerId] = new
    return new
end

-- Blacklist a peer
function resolver.blacklistPeer(peerId)
    blacklist[peerId] = {
        timestamp = os.epoch("utc"),
        expires = os.epoch("utc") + (resolver.CONFIG.blacklistDuration * 1000),
        reason = "Low trust level"
    }
end

-- Check if peer is rate limited
function resolver.isRateLimited(peerId)
    local now = os.epoch("utc")
    local hourAgo = now - 3600000
    local count = 0
    
    for _, dispute in pairs(resolvedDisputes) do
        if dispute.claimant == peerId and dispute.raised > hourAgo then
            count = count + 1
        end
    end
    
    return count >= resolver.CONFIG.maxDisputesPerHour
end

-- Handle dispute messages
-- Start dispute handler
-- This returns the function to be run in parallel, doesn't block
function resolver.startDisputeHandler()
    return function()
        while true do
            local message, senderId = protocol.receiveMessage(protocol.PROTOCOLS.DNS, 0.1)
            
            if message then
                if message.type == "VOTE_REQUEST" then
                    -- Process vote request
                    local vote = resolver.evaluateDispute(message.data)
                    
                    local response = protocol.createMessage(
                        "VOTE_RESPONSE",
                        {
                            disputeId = message.data.disputeId,
                            vote = vote,
                            voter = os.getComputerID()
                        }
                    )
                    
                    protocol.sendMessage(senderId, response, protocol.PROTOCOLS.DNS)
                    
                elseif message.type == "VOTE_RESPONSE" then
                    resolver.handleVote(message, senderId)
                    
                elseif message.type == "DISPUTE_RAISED" then
                    -- Cache dispute information
                    local dispute = message.data.dispute
                    if not activeDisputes[dispute.domain] then
                        activeDisputes[dispute.domain] = dispute
                    end
                end
            end
            
            -- Clean expired disputes
            resolver.cleanExpired()
        end
    end
end

-- Evaluate dispute and decide vote
function resolver.evaluateDispute(disputeData)
    -- Simple evaluation based on evidence
    -- In a real system, this would be more sophisticated
    
    -- Check if we have local knowledge of the domain
    local evidence = disputeData.evidence
    
    -- If claimant provides valid ownership proof, vote for them
    if evidence.ownershipProof then
        return "claimant"
    end
    
    -- Otherwise, tend to support current owner (status quo)
    return "claimed"
end

-- Clean expired disputes and blacklist entries
function resolver.cleanExpired()
    local now = os.epoch("utc")
    
    -- Clean disputes
    for domain, dispute in pairs(activeDisputes) do
        if now > dispute.expires then
            dispute.status = "expired"
            dispute.resolution = "Timed out"
            resolver.finalizeDispute(dispute)
        end
    end
    
    -- Clean blacklist
    for peerId, entry in pairs(blacklist) do
        if now > entry.expires then
            blacklist[peerId] = nil
        end
    end
end

-- Get dispute history
function resolver.getDisputeHistory(domain)
    local history = {}
    
    for id, dispute in pairs(resolvedDisputes) do
        if not domain or dispute.domain == domain then
            table.insert(history, {
                id = dispute.id,
                domain = dispute.domain,
                raised = dispute.raised,
                resolution = dispute.resolution,
                winner = dispute.winner
            })
        end
    end
    
    -- Sort by date
    table.sort(history, function(a, b)
        return a.raised > b.raised
    end)
    
    return history
end

-- Get active disputes
function resolver.getActiveDisputes()
    local disputes = {}
    
    for domain, dispute in pairs(activeDisputes) do
        table.insert(disputes, {
            domain = domain,
            status = dispute.status,
            raised = dispute.raised,
            expires = dispute.expires
        })
    end
    
    return disputes
end

return resolver