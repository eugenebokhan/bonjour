# Bonjour

Bonjour is a little singleton service for easy communication with `bonjour protocol supported` devices.

## Requirements

* Xcode 10
* Swift 4.2

## How To Install

```ruby
pod 'Bonjour'
```

## How To Use

* Setup delegates:
  ```swift
  // Add your class to delegates dictionary
  BonjourService.shared.delegates["MyDelegateClass"] = self

  // Remove your class from delegates when it's necessary
  BonjourService.shared.delegates.removeValue(forKey: "MyDelegateClass")
  ```
* Start/stop broadcasting:
  ```swift
  // Start broadcasting
  BonjourService.shared.startBroadcasting()

  // Stop broadcasting
  BonjourService.shared.stopBroadcasting()
  ```
* Implement delegate methods:
  ```swift
  func updateConnectionStatus(isConnected: Bool)
  func didConnect(to host: String!, port: UInt16)
  func didAcceptNewSocket()
  func socketDidDisconnect()
  func didWriteData(tag: Int)
  func didRead(data: Data, tag: Int)  
  func netServiceDidPublish(_ netService: NetService)
  func netServiceDidNotPublish(_ netService: NetService)
  ```

## Author

| [<img src="https://avatars1.githubusercontent.com/u/8983647?s=460&amp;v=4" width="120px;"/>](https://github.com/eugenebokhan)   | [Eugene Bokhan](https://github.com/eugenebokhan)<br/><br/><sub>iOS Software Engineer</sub><br/> [![Twitter][1.1]][1] [![Github][2.1]][2] [![LinkedIn][3.1]][3]|
| - | :- |

[1.1]: http://i.imgur.com/wWzX9uB.png (twitter icon without padding)
[2.1]: http://i.imgur.com/9I6NRUm.png (github icon without padding)
[3.1]: https://www.kingsfund.org.uk/themes/custom/kingsfund/dist/img/svg/sprite-icon-linkedin.svg (linkedin icon)

[1]: https://twitter.com/eugenebokhan
[2]: https://github.com/eugenebokhan
[3]: https://www.linkedin.com/in/eugenebokhan/

## License

[Project's license](LICENSE) is based on the BSD 3-Clause.
