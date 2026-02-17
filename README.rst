pyenet-dtls
===========

pyenet-dtls is a Python wrapper for the `ENet <http://enet.bespin.org>`_
UDP networking library with DTLS (Datagram Transport Layer Security)
support via OpenSSL.

It is a fork of `pyenet <https://github.com/piqueserver/pyenet>`_, originally
written by Scott Robinson and maintained by Andrew Resch and the piqueserver
team.

Features
--------

- Full Python 3 support (Cython 3)
- Optional DTLS encryption for secure UDP communication
- Builds with or without OpenSSL (DTLS is automatically enabled when OpenSSL
  is available)
- Pre-built wheels for Linux, Windows, and macOS

License
-------

pyenet-dtls is licensed under the BSD license, see LICENSE for details. ENet
is licensed under the MIT license, see
http://enet.bespin.org/License.html

Dependencies
------------

- Python >= 3.9
- Cython >= 3
- OpenSSL development headers

Installation
------------

From PyPI
~~~~~~~~~

::

    pip install pyenet-dtls

From source
~~~~~~~~~~~

::

    git clone --recursive <repo-url>
    cd pyenet
    pip install .

Building wheels
~~~~~~~~~~~~~~~

Build locally using Docker/Podman (Linux only)::

    ./scripts/build_packages.sh

Wheels are output to the ``wheelhouse/`` directory.

For all platforms (Linux, Windows, macOS), push to GitHub and use the
**Wheel build** workflow, or create a release to trigger the **Publish to
PyPI** workflow.

Usage
-----

Basic example (no DTLS):

::

    >>> import enet

    >>> # Server
    >>> server = enet.Host(enet.Address("localhost", 33333), 32, 2, 0, 0)
    >>> event = server.service(1000)

    >>> # Client
    >>> client = enet.Host(None, 1, 2, 0, 0)
    >>> peer = client.connect(enet.Address("localhost", 33333), 2)

With DTLS encryption:

::

    >>> import enet

    >>> # Server with TLS certificate
    >>> server = enet.Host(enet.Address("localhost", 33333), 32, 2, 0, 0,
    ...                    dtls_cert="server.pem", dtls_key="server.key")

    >>> # Client connecting with DTLS
    >>> client = enet.Host(None, 1, 2, 0, 0)
    >>> peer = client.connect(enet.Address("localhost", 33333), 2, dtls=True)

Check if DTLS support is available::

    >>> import enet
    >>> print(enet.DTLS_AVAILABLE)
    True

Generating a self-signed certificate
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DTLS requires a certificate and private key for the server. To generate a
self-signed certificate for testing or development::

    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout server.key -out server.pem \
        -days 365 -subj "/CN=localhost"

This creates ``server.pem`` (certificate) and ``server.key`` (private key)
valid for 365 days. For production use, obtain a certificate from a trusted
certificate authority.

More information on ENet usage can be found at:
http://enet.bespin.org/Tutorial.html
