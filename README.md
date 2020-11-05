# Bonjour

Bonjour is a little service for easy communication with [`bonjour protocol`](https://developer.apple.com/bonjour/) supported devices.

## Requirements

* Swift `5.2`
* iOS `11.0`
* macOS `10.13`

## Install via [`Cocoapods`](https://cocoapods.org)

```ruby
pod 'Bonjour'
```

## How To Use

* Init session

  ```swift
  let bonjour = BonjourSession(configuration: .init(configuration: .default))
  ```

* Start / stop session:
  ```swift
  // Start broadcasting
  bonjour.start()

  // Stop broadcasting
  bonjour.stop()
  ```
* Implement optional handlers:

  ```swift
  // On start receiving large package of data.
  bonjour.onStartRecieving = { resourceName, peer in ... }

  // Track large package of data receiving progress.
  bonjour.onReceiving = { resourceName, progress in ... }

  // On finish receiving large package of data.
  bonjour.onFinishRecieving = { resourceName, peer, localURL, error in ... }

  // On small package of data receive.
  bonjour.onReceive = { data, peer in ... }

  // On new peer discovery.
  bonjour.onPeerDiscovery = { peer in ... }

  // On loss of peer.
  bonjour.onPeerLoss = { peer in ... }

  // On connection to peer.
  bonjour.onPeerConnection = { peer in ... }

  // On disconnection from peer.
  bonjour.onPeerDisconnection = { peer in ... }

  // On update of list of available peers.
  bonjour.onAvailablePeersDidChange = { availablePeers in ... }
  ```

* Send messages/data:
  ```Swift
  // Send small package of data to all connected peers.
  bonjour.broadcast(_ data: Data)

  // Send small package of data to certain amount of connected peers.
  bonjour.send(_ data: Data, to peers: [Peer])

  // Send large package of data to a certain peer.
  bonjour.sendResource(at url: URL,
                       resourceName: String,
                       to peer: Peer,
                       progressHandler: ((Double) -> Void)?,
                       completionHandler: ((Error?) -> Void)?)
  ```

## Info.plist configuration

In order for `BonjourSession` to work when running on iOS 14, you will have to include two keys in your app's Info.plist file.

The keys are `Privacy - Local Network Usage Description` (`NSLocalNetworkUsageDescription`) and `Bonjour services` (`NSBonjourServices`).

For the privacy key, include a human-readable description of what benefit the user gets by allowing your app to access devices on the local network.

The Bonjour services key is an array of service types that your app will browse for. For `BonjourSession`, the entry should be in the format `_servicename._tcp`, where `servicename` is the `serviceType` you've set in your `MultipeerConfiguration`. If you're using the default configuration, the value of this key should be `_Bonjour._tcp`.

**If you do not configure the above keys properly, then `BonjourSession` won't work.**

## License

Project's license is [MIT](LICENSE).
