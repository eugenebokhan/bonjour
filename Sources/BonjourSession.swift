import Foundation
import MultipeerConnectivity
import os.log

public typealias InvitationCompletionHandler = (_ result: Result<Peer, Error>) -> Void

public protocol BonjourSessionDelegate: AnyObject {
    func didReceive(data: Data, from peer: String)
    func didDiscover(peer: Peer)
    func didLose(peer: Peer)
    func didConnect(to peer: Peer)
    func didDisconnect(from peer: Peer)
    func availablePeersDidChange(peers: [Peer])
}

final public class BonjourSession: NSObject {

    // MARK: - Type Definitions

    public struct Configuration {

        public enum Invitation {
            case automatic
            case custom((Peer) throws -> (context: Data, timeout: TimeInterval)?)
            case none
        }

        public struct Security {

            public typealias InvitationHandler = (Peer, Data?, @escaping (Bool) -> Void) -> Void

            public var identity: [Any]?
            public var encryptionPreference: MCEncryptionPreference
            public var invitationHandler: InvitationHandler

            public init(identity: [Any]?,
                        encryptionPreference: MCEncryptionPreference,
                        invitationHandler: @escaping InvitationHandler) {
                self.identity = identity
                self.encryptionPreference = encryptionPreference
                self.invitationHandler = invitationHandler
            }

            public static let `default` = Security(identity: nil,
                                                   encryptionPreference: .none) { _, _, closure in closure(true) }

        }

        public var serviceType: String
        public var peerName: String
        public var defaults: UserDefaults
        public var security: Security
        public var invitation: Invitation
        public init(serviceType: String,
                    peerName: String,
                    defaults: UserDefaults,
                    security: Security,
                    invitation: Invitation) {
            precondition(peerName.utf8.count <= 63, "peerName can't be longer than 63 bytes")

            self.serviceType = serviceType
            self.peerName = peerName
            self.defaults = defaults
            self.security = security
            self.invitation = invitation
        }

        public static let `default` = Configuration(serviceType: "Bonjour",
                                                    peerName: MCPeerID.defaultDisplayName,
                                                    defaults: .standard,
                                                    security: .default,
                                                    invitation: .automatic)
    }


    public enum BonjourSessionError: LocalizedError {
        case connectionToPeerfailed

        var localizedDescription: String {
            switch self {
            case .connectionToPeerfailed: return "Failed to connect to peer."
            }
        }
    }

    public struct Usage: OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let receive = Usage(rawValue: 0x1)
        public static let transmit = Usage(rawValue: 0x2)
        public static let combined: Usage = [.receive, .transmit]
    }

    // MARK: - Properties

    public let usage: Usage
    public let configuration: Configuration
    public let localPeerID: MCPeerID

    public private(set) var availablePeers: Set<Peer> = [] {
        didSet {
            guard availablePeers != oldValue
            else { return }
            DispatchQueue.main.async {
                self.delegate?.availablePeersDidChange(peers: Array(self.availablePeers))
            }
        }
    }

    public weak var delegate: BonjourSessionDelegate? = nil

    private lazy var session: MCSession = {
        let session = MCSession(peer: self.localPeerID,
                                securityIdentity: self.configuration.security.identity,
                                encryptionPreference: self.configuration.security.encryptionPreference)
        session.delegate = self
        return session
    }()

    private lazy var browser: MCNearbyServiceBrowser = {
        let browser = MCNearbyServiceBrowser(peer: self.localPeerID,
                                             serviceType: self.configuration.serviceType)
        browser.delegate = self
        return browser
    }()

    private lazy var advertiser: MCNearbyServiceAdvertiser = {
        let advertiser = MCNearbyServiceAdvertiser(peer: self.localPeerID,
                                                   discoveryInfo: nil,
                                                   serviceType: self.configuration.serviceType)
        advertiser.delegate = self
        return advertiser
    }()

    private var invitationCompletionHandlers: [MCPeerID: InvitationCompletionHandler] = [:]


    // MARK: - Init

    public init(usage: Usage = .combined,
                configuration: Configuration = .default) {
        self.usage = usage
        self.configuration = configuration
        self.localPeerID = MCPeerID.fetchOrCreate(with: configuration)
    }

    public func start() {
        #if DEBUG
        os_log("%{public}@",
               log: .default,
               type: .debug,
               #function)
        #endif
        
        if self.usage.contains(.receive) {
            self.advertiser.startAdvertisingPeer()
        }
        if self.usage.contains(.transmit) {
            self.browser.startBrowsingForPeers()
        }
    }
    
    public func stop() {
        #if DEBUG
        os_log("%{public}@",
               log: .default,
               type: .debug,
               #function)
        #endif
        
        if self.usage.contains(.receive) {
            self.advertiser.stopAdvertisingPeer()
        }
        if self.usage.contains(.transmit) {
            self.browser.stopBrowsingForPeers()
        }
    }



    public func broadcast(_ data: Data) throws {
        guard !self.session.connectedPeers.isEmpty else {
            #if DEBUG
            os_log("Not broadcasting message: no connected peers",
                   log: .default,
                   type: .error)
            #endif
            return
        }

        try self.session.send(data,
                              toPeers: self.session.connectedPeers,
                              with: .reliable)
    }

    public func send(_ data: Data,
              to peers: [Peer]) throws {
        let ids = peers.map { $0.peerID }
        try self.session.send(data,
                              toPeers: ids,
                              with: .reliable)
    }

    public func invite(_ peer: Peer,
                       with context: Data?,
                       timeout: TimeInterval,
                       completion: InvitationCompletionHandler?) {
        self.invitationCompletionHandlers[peer.peerID] = completion

        self.browser.invitePeer(peer.peerID,
                                to: self.session,
                                withContext: context,
                                timeout: timeout)
    }

    private func didDiscover(_ peer: Peer) {
        self.availablePeers.insert(peer)
        self.delegate?.didDiscover(peer: peer)
    }

    private func handlePeerRemoved(_ peerID: MCPeerID) {
        guard let peer = self.availablePeers.first(where: { $0.peerID == peerID })
        else { return }
        self.availablePeers.remove(peer)
        self.delegate?.didLose(peer: peer)
    }

    private func handlePeerConnected(_ peer: Peer) {
        self.setConnected(true, on: peer)
        self.delegate?.didConnect(to: peer)
    }

    private func handlePeerDisconnected(_ peer: Peer) {
        self.setConnected(false, on: peer)
        self.delegate?.didDisconnect(from: peer)
    }

    private func setConnected(_ connected: Bool, on peer: Peer) {
        guard let idx = self.availablePeers.firstIndex(where: { $0.peerID == peer.peerID })
        else { return }

        var mutablePeer = self.availablePeers[idx]
        mutablePeer.isConnected = connected
        self.availablePeers.remove(peer)
        self.availablePeers.insert(mutablePeer)
    }

}

// MARK: - Session delegate

extension BonjourSession: MCSessionDelegate {

    public func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        #if DEBUG
        os_log("%{public}@",
               log: .default,
               type: .debug, #function)
        #endif
        
        guard let peer = self.availablePeers.first(where: { $0.peerID == peerID })
        else { return }

        let handler = self.invitationCompletionHandlers[peerID]

        DispatchQueue.main.async {
            switch state {
            case .connected:
                handler?(.success(peer))
                self.invitationCompletionHandlers[peerID] = nil
                self.delegate?.didConnect(to: peer)
            case .notConnected:
                handler?(.failure(BonjourSessionError.connectionToPeerfailed))
                self.invitationCompletionHandlers[peerID] = nil
                self.delegate?.didDisconnect(from: peer)
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    public func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        #if DEBUG
        os_log("%{public}@", log: .default, type: .debug, #function)
        #endif
        self.delegate?.didReceive(data: data,
                                  from: peerID.displayName)
    }

    public func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        #if DEBUG
        os_log("%{public}@", log: .default, type: .debug, #function)
        #endif
    }

    public func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        #if DEBUG
        os_log("%{public}@", log: .default, type: .debug, #function)
        #endif
    }

    public func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
        #if DEBUG
        os_log("%{public}@", log: .default, type: .debug, #function)
        #endif
    }

}

// MARK: - Browser delegate

extension BonjourSession: MCNearbyServiceBrowserDelegate {

    public func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        #if DEBUG
        os_log("%{public}@", log: .default, type: .debug, #function)
        #endif

        do {
            let peer = try Peer(peer: peerID, discoveryInfo: info)

            self.didDiscover(peer)

            switch configuration.invitation {
            case .automatic:
                browser.invitePeer(peerID,
                                   to: self.session,
                                   withContext: nil,
                                   timeout: 10.0)
            case .custom(let inviter):
                guard let invite = try inviter(peer)
                else {
                    #if DEBUG
                    os_log("Custom invite not sent for peer %@",
                    log: .default,
                    type: .error,
                    String(describing: peer))
                    #endif
                    return
                }

                browser.invitePeer(peerID,
                                   to: self.session,
                                   withContext: invite.context,
                                   timeout: invite.timeout)
            case .none:
                #if DEBUG
                os_log("Auto-invite disabled",
                       log: .default,
                       type: .debug)
                #endif
                return
            }
        } catch {
            #if DEBUG
            os_log("Failed to initialize peer based on peer ID %@: %{public}@",
                   log: .default,
                   type: .error,
                   String(describing: peerID),
                   String(describing: error))
            #endif
        }
    }

    public func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        #if DEBUG
        os_log("%{public}@", log: .default, type: .debug, #function)
        #endif
        self.handlePeerRemoved(peerID)
    }

}

// MARK: - Advertiser delegate

extension BonjourSession: MCNearbyServiceAdvertiserDelegate {

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        #if DEBUG
        os_log("%{public}@", log: .default, type: .debug, #function)
        #endif

        guard let peer = self.availablePeers.first(where: { $0.peerID == peerID })
        else { return }

        self.configuration.security.invitationHandler(peer, context, { [weak self] decision in
            guard let self = self
            else { return }
            invitationHandler(decision, decision ? self.session : nil)
        })
    }

}
