| Step | MAKVONotificationCenter | libextobjc | FXReachability | SRG Logger | SRG Appearance | SRG Network | SRG Diagnostics | SRG Media Player | SRG Data Provider | SRG Content Protection | SRG Content Protection Fake | SRG Analytics | SRG Letterbox |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Start git-flow release branch for new version ||||||||||||||
| Perform global diff with last release ||||||||||||||
| Verify version number in project. Bump minor in case of breaking API changes ||||||||||||||
| Edit Cartfile to point at tagged versions ||||||||||||||
| Verify that Cartfile.resolved only contains tagged versions ||||||||||||||
| Run `make update` ||||||||||||||
| Run unit tests successfully ||||||||||||||
| Finish git-flow release ||||||||||||||
| Bump patch / build version numbers in project ||||||||||||||
| Push master, develop and tag ||||||||||||||
| Close milestone and issues on github ||||||||||||||
| Create github release ||||||||||||||
| Deliver demo on HockeyApp | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A ||
| Update dependency matrix on wiki | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A ||



