## [1.3.4](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.3.3...v1.3.4) (2025-06-13)


### Bug Fixes

* delegations tests for dns resolver and aks api subnet ([556e73b](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/556e73bc218bf4379d3e10b2c4b48ab0cd50e1f1))
* test case was looking for the wrong delegations for aks_api subnet ([106df7c](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/106df7c21899d16d2a1f8df9d6931cb55fc2c8b9))
* use intepreter to run the script files provided with the provider ([bf4d9c4](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/bf4d9c4e4a454af43437b40d5917266274c6cd80))

## [1.3.3](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.3.2...v1.3.3) (2025-06-13)


### Bug Fixes

* delegation of api server subnet ([2eecfcf](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/2eecfcfc169a1bf9427bbc6ac99a4cf459f87965))

## [1.3.2](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.3.1...v1.3.2) (2025-06-12)


### Bug Fixes

* delegations were not set for aks api server subnet and dns resolver subnet ([3fa561d](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/3fa561d1a3f61418e4d16a48d98ad7a61cebaafe))

## [1.3.2-beta.1](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.3.1...v1.3.2-beta.1) (2025-06-12)


### Bug Fixes

* delegations were not set for aks api server subnet and dns resolver subnet ([3fa561d](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/3fa561d1a3f61418e4d16a48d98ad7a61cebaafe))

## [1.3.1](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.3.0...v1.3.1) (2025-06-11)


### Bug Fixes

* updated provider versions ([cc07889](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/cc078890c722d97601840bb5d8ccf7b995ac4ae7))

## [1.3.1-beta.1](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.3.0...v1.3.1-beta.1) (2025-06-11)


### Bug Fixes

* updated provider versions ([cc07889](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/cc078890c722d97601840bb5d8ccf7b995ac4ae7))

# [1.3.0](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.2.0...v1.3.0) (2025-04-01)


### Features

* adding workflows to keeping a major version tag uptodat with minor and patch versions ([d61a8f7](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/d61a8f723a0f0cfe2f8746f6b78a6a83d6728a81))

# [1.3.0-beta.1](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.2.0...v1.3.0-beta.1) (2025-04-01)


### Features

* adding workflows to keeping a major version tag uptodat with minor and patch versions ([d61a8f7](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/d61a8f723a0f0cfe2f8746f6b78a6a83d6728a81))

# [1.2.0](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.1.0...v1.2.0) (2025-03-27)


### Features

* Changed license model ([e205d47](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/e205d479f7fa17cb15a4f49ae9ddc4c15c82fae2))

# [1.2.0-beta.1](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.1.0...v1.2.0-beta.1) (2025-03-27)


### Features

* Changed license model ([e205d47](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/e205d479f7fa17cb15a4f49ae9ddc4c15c82fae2))

# [1.1.0](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.0.0...v1.1.0) (2025-03-27)


### Features

* Adding input list of ingress gateway names to reserve ips for ([cf6f1e8](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/cf6f1e8f98a49ebbb55b4a17a29ef740111dc4b9))

# [1.1.0-beta.1](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.0.0...v1.1.0-beta.1) (2025-03-26)


### Features

* Adding input list of ingress gateway names to reserve ips for ([cf6f1e8](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/cf6f1e8f98a49ebbb55b4a17a29ef740111dc4b9))

# 1.0.0 (2025-03-25)


### Bug Fixes

* adding next branch to release workflow ([40f3b08](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/40f3b08f82a53d3edb6c819a150e2a9c295b09a3))
* moved to terraform test from terratest ([51bf78b](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/51bf78b6eaf5714912f2be906cb0164d09fe2150))
* sarif upoload in tfsec workflow ([a562022](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/a5620221c398a62104d14198a3a443f9f76d77b9))


### Features

* Setting cloudflare public ips and cgnat to default allowed dmz ingress ([0cbd7b4](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/0cbd7b47fbfb4d13dd3401b6e1f6cbb08d9c583b))

# [1.0.0-beta.2](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/compare/v1.0.0-beta.1...v1.0.0-beta.2) (2025-03-25)


### Bug Fixes

* moved to terraform test from terratest ([51bf78b](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/51bf78b6eaf5714912f2be906cb0164d09fe2150))
* sarif upoload in tfsec workflow ([a562022](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/a5620221c398a62104d14198a3a443f9f76d77b9))


### Features

* Setting cloudflare public ips and cgnat to default allowed dmz ingress ([0cbd7b4](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/0cbd7b47fbfb4d13dd3401b6e1f6cbb08d9c583b))

# 1.0.0-beta.1 (2025-03-22)


### Bug Fixes

* adding next branch to release workflow ([40f3b08](https://github.com/MonsieurDahlstrom/tf-azure-lz-network/commit/40f3b08f82a53d3edb6c819a150e2a9c295b09a3))
