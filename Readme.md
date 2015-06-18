![readme_logo](https://cloud.githubusercontent.com/assets/213293/8223759/0eb48b8e-154a-11e5-9a56-fbd2d91fc0e7.png)

Hangover is the first native Mac client for Hangouts, Google's instant
messaging service. At the moment, it is essentially a native Swift port of [Tom
Dryer's `hangups`](https://github.com/tdryer/hangups), which was the first
third-party Google Hangouts client. In the long term, Hangover is intended
to be the Google Hangouts client that Google forgot to make for Mac OS X.

At the moment, Hangover is an extremely alpha project. It is slowly becoming
usable as a chat client.
Most of the code has simply been ported over from [the original
Python](https://github.com/tdryer/hangups) to Swift, and it's not pretty.
(Forgive me for the sins I've committed while hacking this together.)

## Screenshots

![ooh pretty](https://cloud.githubusercontent.com/assets/213293/8223288/f3b88bb0-1543-11e5-9aaf-d8f90eadd8e3.png)


## Documentation

Not yet.

## Contributing

Contributions welcomed! Please open issues on the project and send pull requests.

At the moment, Hangover is written in Swift 2.0, which means that you'll need
[Xcode 7 beta](https://developer.apple.com/xcode/downloads/) to even compile
the app. As well, you'll notice that the Podfile is conspicuously empty. All
dependencies must also be in Swift 2.0 (or Objective C), so the Podfile points
at [a fork of the Alamofire Swift networking
library](https://github.com/psobot/alamofire/tree/swift2b1) that has been
ported to Swift 2.

## License

MIT. See [LICENSE](https://github.com/psobot/hangover/blob/master/LICENSE).
