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

## Author

| [<img src="https://avatars1.githubusercontent.com/u/8983647?s=460&amp;v=4" width="120px;"/>](https://github.com/eugenebokhan)   | [Eugene Bokhan](https://github.com/eugenebokhan)<br/><br/><sub>Software Engineer</sub><br/> [![Twitter][1.1]][1] [![Github][2.1]][2] [![LinkedIn][3.1]][3]|
| - | :- |

[1.1]: http://i.imgur.com/wWzX9uB.png (twitter icon without padding)
[2.1]: http://i.imgur.com/9I6NRUm.png (github icon without padding)
[3.1]: https://www.kingsfund.org.uk/themes/custom/kingsfund/dist/img/svg/sprite-icon-linkedin.svg (linkedin icon)

[1]: https://twitter.com/eugenebokhan
[2]: https://github.com/eugenebokhan
[3]: https://www.linkedin.com/in/eugenebokhan/

## License

Project's license is [MIT](LICENSE).
