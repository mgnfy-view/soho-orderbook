<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]


<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/mgnfy-view/soho-orderbook">
    <img src="images/icon.png" alt="Logo" width="280">
  </a>

  <h3 align="center">Soho Orderbook</h3>

  <p align="center">
    Soho is a central limit order-book protocol for high frequency, gasless trades on multiple chains including Blast
    <br />
    <a href="https://github.com/mgnfy-view/soho-orderbook/tree/main/docs"><strong>Explore the docs »</strong></a>
    <br />
    <a href="https://github.com/mgnfy-view/soho-orderbook/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    ·
    <a href="https://github.com/mgnfy-view/soho-orderbook/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>


<!-- ABOUT THE PROJECT -->
## About The Project

Soho is a central limit orderbook protocol to facilitate high-frequency, gasless trades on multiple chains including Blast.

The protocol consists of three main actors: a maker, a taker, and an off-chain matching engine. Users can start placing ask/sell orders on the off-chain engine after they have deposited some tokens into the on-chain settlement protocol. An ask order brings liquidity to the market, whereas a sell order takes liquidity from the market. Makers and takers can sign their respective orders off-chain. Once a mirrored maker and taker order is matched, the matching engine settles it on-chain using the `Soho::settleOrders()` function and the maker and taker signatures. The protocol takes a small percentage of fees from the taker's input amount, so it is necessary that takers put up some buffer amount to have their orders matched.

The protocol uses bitmaps to efficiently track the resolution status of an order, and EIP712 signatures to sign orders.

The protocol can be deployed on multiple evm-compatible chains, and is also configured for Blast.

### Built With

- ![Foundry](https://img.shields.io/badge/-FOUNDRY-%23323330.svg?style=for-the-badge)
- ![Solidity](https://img.shields.io/badge/Solidity-%23363636.svg?style=for-the-badge&logo=solidity&logoColor=white)


<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

Make sure you have git and foundry installed and configured on your system.

### Installation

Clone the repo,

```shell
git clone https://github.com/mgnfy-view/soho-orderbook.git
```

cd into the repo, and install the necessary dependencies

```shell
cd soho-orderbook
forge test
```

That's it, you are good to go now!


<!-- ROADMAP -->
## Roadmap

- [x] Smart contract development
- [x] Unit tests
- [x] Write Docs
- [x] Write a good README.md

See the [open issues](https://github.com/mgnfy-view/soho-orderbook/issues) for a full list of proposed features (and known issues).


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.


<!-- CONTACT -->
## Reach Out

Here's a gateway to all my socials, don't forget to hit me up!

[![Linktree](https://img.shields.io/badge/linktree-1de9b6?style=for-the-badge&logo=linktree&logoColor=white)][linktree-url]


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/mgnfy-view/soho-orderbook.svg?style=for-the-badge
[contributors-url]: https://github.com/mgnfy-view/soho-orderbook/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/mgnfy-view/soho-orderbook.svg?style=for-the-badge
[forks-url]: https://github.com/mgnfy-view/soho-orderbook/network/members
[stars-shield]: https://img.shields.io/github/stars/mgnfy-view/soho-orderbook.svg?style=for-the-badge
[stars-url]: https://github.com/mgnfy-view/soho-orderbook/stargazers
[issues-shield]: https://img.shields.io/github/issues/mgnfy-view/soho-orderbook.svg?style=for-the-badge
[issues-url]: https://github.com/mgnfy-view/soho-orderbook/issues
[license-shield]: https://img.shields.io/github/license/mgnfy-view/soho-orderbook.svg?style=for-the-badge
[license-url]: https://github.com/mgnfy-view/soho-orderbook/blob/master/LICENSE.txt
[linktree-url]: https://linktr.ee/mgnfy.view