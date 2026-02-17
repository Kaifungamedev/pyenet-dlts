import atexit

from libc.stdint cimport uintptr_t
from libc.string cimport memcpy

cdef extern from "Python.h":
    cdef void Py_INCREF(object o)
    cdef void Py_DECREF(object o)

cdef extern from "enet/types.h":
    ctypedef unsigned char enet_uint8
    ctypedef unsigned short enet_uint16
    ctypedef unsigned int enet_uint32
    ctypedef unsigned int size_t

cdef extern from "enet/enet.h":

    ctypedef enet_uint32 ENetVersion
    # forward declaration
    ctypedef struct ENetPeer
    ctypedef struct ENetHost

    cdef enum:
        ENET_HOST_ANY = 0
        ENET_HOST_BROADCAST = 0xFFFFFFFF
        ENET_PORT_ANY = 0

    ctypedef int ENetSocket

    ctypedef struct ENetBuffer:
        void *data
        size_t dataLength

    ctypedef struct ENetEvent

    ctypedef int (__cdecl *ENetInterceptCallback) (ENetHost *host, ENetEvent *event) except -1 # __cdecl is standard on unix and overwriten for win32
    ctypedef int (__cdecl *ENetSendCallback) (ENetHost *host, ENetSocket socket, const ENetAddress *address, const ENetBuffer *buffers, size_t bufferCount) noexcept
    ctypedef void (__cdecl *ENetPacketFreeCallback) (ENetPacket *)

    ctypedef struct ENetAddress:
        enet_uint32 host
        enet_uint16 port

    ctypedef enum ENetPacketFlag:
        ENET_PACKET_FLAG_RELIABLE = (1 << 0)
        ENET_PACKET_FLAG_UNSEQUENCED = (1 << 1)
        ENET_PACKET_FLAG_NO_ALLOCATE = (1 << 2)
        ENET_PACKET_FLAG_UNRELIABLE_FRAGMENT = (1 << 3)

    ctypedef struct ENetPacket:
        size_t referenceCount
        enet_uint32 flags
        enet_uint8 *data
        size_t dataLength
        ENetPacketFreeCallback freeCallback
        void* userData

    ctypedef enum ENetPeerState:
        ENET_PEER_STATE_DISCONNECTED = 0
        ENET_PEER_STATE_CONNECTING = 1
        ENET_PEER_STATE_ACKNOWLEDGING_CONNECT = 2
        ENET_PEER_STATE_CONNECTION_PENDING = 3
        ENET_PEER_STATE_CONNECTION_SUCCEEDED = 4
        ENET_PEER_STATE_CONNECTED = 5
        ENET_PEER_STATE_DISCONNECT_LATER = 6
        ENET_PEER_STATE_DISCONNECTING = 7
        ENET_PEER_STATE_ACKNOWLEDGING_DISCONNECT = 8
        ENET_PEER_STATE_ZOMBIE = 9

    ctypedef struct ENetPeer:
        ENetHost *host
        enet_uint16 outgoingPeerID
        enet_uint16 incomingPeerID
        enet_uint32 connectID
        enet_uint8 outgoingSessionID
        enet_uint8 incomingSessionID
        ENetAddress address
        char *data
        ENetPeerState state
        size_t channelCount
        enet_uint32 incomingBandwidth
        enet_uint32 outgoingBandwidth
        enet_uint32 incomingBandwidthThrottleEpoch
        enet_uint32 outgoingBandwidthThrottleEpoch
        enet_uint32 incomingDataTotal
        enet_uint32 outgoingDataTotal
        enet_uint32 lastSendTime
        enet_uint32 lastReceiveTime
        enet_uint32 nextTimeout
        enet_uint32 earliestTimeout
        enet_uint32 packetLossEpoch
        enet_uint32 packetsSent
        enet_uint32 packetsLost
        enet_uint32 packetLoss
        enet_uint32 packetLossVariance
        enet_uint32 packetThrottle
        enet_uint32 packetThrottleLimit
        enet_uint32 packetThrottleCounter
        enet_uint32 packetThrottleEpoch
        enet_uint32 packetThrottleAcceleration
        enet_uint32 packetThrottleDeceleration
        enet_uint32 packetThrottleInterval
        enet_uint32 lastRoundTripTime
        enet_uint32 lowestRoundTripTime
        enet_uint32 lastRoundTripTimeVariance
        enet_uint32 highestRoundTripTimeVariance
        enet_uint32 roundTripTime
        enet_uint32 roundTripTimeVariance
        enet_uint32 mtu
        enet_uint32 windowSize
        enet_uint32 reliableDataInTransit
        enet_uint16 outgoingReliableSequenceNumber
        enet_uint16 incomingUnsequencedGroup
        enet_uint16 outgoingUnsequencedGroup
        enet_uint32 unsequencedWindow
        enet_uint32 eventData
        enet_uint16 flags

    ctypedef struct ENetHost:
        ENetSocket socket
        ENetAddress address
        enet_uint32 incomingBandwidth
        enet_uint32 outgoingBandwidth
        ENetPeer *peers
        size_t peerCount
        size_t channelLimit
        enet_uint8 packetData[2][4096]
        enet_uint8 *receivedData
        size_t receivedDataLength
        ENetAddress receivedAddress
        enet_uint32 totalSentData
        enet_uint32 totalSentPackets
        enet_uint32 totalReceivedData
        enet_uint32 totalReceivedPackets
        ENetInterceptCallback intercept
        ENetSendCallback sendCallback

    ctypedef enum ENetEventType:
        ENET_EVENT_TYPE_NONE = 0
        ENET_EVENT_TYPE_CONNECT = 1
        ENET_EVENT_TYPE_DISCONNECT = 2
        ENET_EVENT_TYPE_RECEIVE = 3

    ctypedef struct ENetEvent:
        ENetEventType type
        ENetPeer *peer
        enet_uint8 channelID
        enet_uint32 data
        ENetPacket *packet

    ctypedef enum ENetPeerFlag:
        ENET_PEER_FLAG_NEEDS_DISPATCH = (1 << 0)

    # Global functions
    int enet_initialize()
    void enet_deinitialize()

    # Address functions
    int enet_address_set_host(ENetAddress *address, char *hostName)
    int enet_address_get_host_ip(ENetAddress *address, char *hostName, size_t nameLength)
    int enet_address_get_host(ENetAddress *address, char *hostName, size_t nameLength)

    # Packet functions
    ENetPacket* enet_packet_create(char *dataContents, size_t dataLength, enet_uint32 flags)
    void enet_packet_destroy(ENetPacket *packet)
    int enet_packet_resize(ENetPacket *packet, size_t dataLength)

    # Host functions
    int enet_host_compress_with_range_coder(ENetHost *host)
    ENetHost* enet_host_create(ENetAddress *address, size_t peerCount, size_t channelLimit, enet_uint32 incomingBandwidth, enet_uint32 outgoingBandwidth)
    void enet_host_destroy(ENetHost *host)
    ENetPeer* enet_host_connect(ENetHost *host, ENetAddress *address, size_t channelCount, enet_uint32 data)
    void enet_host_broadcast(ENetHost *host, enet_uint8 channelID, ENetPacket *packet)
    void enet_host_channel_limit(ENetHost *host, size_t channelLimit)
    void enet_host_bandwidth_limit(ENetHost *host, enet_uint32 incomingBandwidth, enet_uint32 outgoingBandwidth)
    void enet_host_flush(ENetHost *host)
    int enet_host_check_events(ENetHost *host, ENetEvent *event)
    int enet_host_service(ENetHost *host, ENetEvent *event, enet_uint32 timeout)

    # Peer functions
    void enet_peer_throttle_configure(ENetPeer *peer, enet_uint32 interval, enet_uint32 acceleration, enet_uint32 deacceleration)
    int enet_peer_send(ENetPeer *peer, enet_uint8 channelID, ENetPacket *packet)
    ENetPacket* enet_peer_receive(ENetPeer *peer, enet_uint8 *channelID)
    void enet_peer_ping(ENetPeer *peer)
    void enet_peer_reset(ENetPeer *peer)
    void enet_peer_disconnect(ENetPeer *peer, enet_uint32 data)
    void enet_peer_disconnect_now(ENetPeer *peer, enet_uint32 data)
    void enet_peer_disconnect_later(ENetPeer *peer, enet_uint32 data)

    # Socket functions
    int enet_socket_send(ENetSocket socket, ENetAddress *address, ENetBuffer *buffer, size_t size)

cdef enum:
    MAXHOSTNAME = 257

PACKET_FLAG_RELIABLE = ENET_PACKET_FLAG_RELIABLE
PACKET_FLAG_UNSEQUENCED = ENET_PACKET_FLAG_UNSEQUENCED
PACKET_FLAG_NO_ALLOCATE = ENET_PACKET_FLAG_NO_ALLOCATE
PACKET_FLAG_UNRELIABLE_FRAGMENT = ENET_PACKET_FLAG_UNRELIABLE_FRAGMENT

EVENT_TYPE_NONE = ENET_EVENT_TYPE_NONE
EVENT_TYPE_CONNECT = ENET_EVENT_TYPE_CONNECT
EVENT_TYPE_DISCONNECT = ENET_EVENT_TYPE_DISCONNECT
EVENT_TYPE_RECEIVE = ENET_EVENT_TYPE_RECEIVE

PEER_STATE_DISCONNECTED = ENET_PEER_STATE_DISCONNECTED
PEER_STATE_CONNECTING = ENET_PEER_STATE_CONNECTING
PEER_STATE_ACKNOWLEDGING_CONNECT = ENET_PEER_STATE_ACKNOWLEDGING_CONNECT
PEER_STATE_CONNECTION_PENDING = ENET_PEER_STATE_CONNECTION_PENDING
PEER_STATE_CONNECTION_SUCCEEDED = ENET_PEER_STATE_CONNECTION_SUCCEEDED
PEER_STATE_CONNECTED = ENET_PEER_STATE_CONNECTED
PEER_STATE_DISCONNECT_LATER = ENET_PEER_STATE_DISCONNECT_LATER
PEER_STATE_DISCONNECTING = ENET_PEER_STATE_DISCONNECTING
PEER_STATE_ACKNOWLEDGING_DISCONNECT = ENET_PEER_STATE_ACKNOWLEDGING_DISCONNECT
PEER_STATE_ZOMBIE = ENET_PEER_STATE_ZOMBIE

from openssl_dtls cimport *

cdef enum:
    DTLS_BUF_SIZE = 65536

cdef class DTLSSession:
    """Per-peer DTLS session wrapping an SSL object with memory BIOs."""
    cdef SSL *ssl
    cdef BIO *rbio
    cdef BIO *wbio
    cdef bint is_server

    def __cinit__(self):
        self.ssl = NULL
        self.rbio = NULL
        self.wbio = NULL

    cdef int init(self, SSL_CTX *ctx, bint is_server) except -1:
        self.is_server = is_server
        self.ssl = SSL_new(ctx)
        if self.ssl == NULL:
            raise MemoryError("Failed to create SSL object")

        self.rbio = BIO_new(BIO_s_mem())
        self.wbio = BIO_new(BIO_s_mem())
        if self.rbio == NULL or self.wbio == NULL:
            raise MemoryError("Failed to create BIO objects")

        # SSL_set_bio takes ownership of the BIOs
        SSL_set_bio(self.ssl, self.rbio, self.wbio)

        if is_server:
            SSL_set_accept_state(self.ssl)
        else:
            SSL_set_connect_state(self.ssl)
        return 0

    cdef int feed_received(self, const unsigned char *data, int length) noexcept:
        """Feed encrypted data from the network into the SSL read BIO."""
        return BIO_write(self.rbio, data, length)

    cdef int try_decrypt(self, unsigned char *out_buf, int out_size) noexcept:
        """Try to read decrypted data from SSL. Returns bytes read or <= 0."""
        return SSL_read(self.ssl, out_buf, out_size)

    cdef int encrypt(self, const unsigned char *data, int length) noexcept:
        """Encrypt data through SSL. Returns bytes written or <= 0."""
        return SSL_write(self.ssl, data, length)

    cdef int read_outgoing(self, unsigned char *out_buf, int out_size) noexcept:
        """Read pending encrypted data from the SSL write BIO."""
        cdef size_t pending = BIO_ctrl_pending(self.wbio)
        if pending <= 0:
            return 0
        if <int>pending > out_size:
            pending = out_size
        return BIO_read(self.wbio, out_buf, pending)

    cdef int do_handshake_step(self) noexcept:
        """Drive one step of DTLS handshake.
        Returns 1 when done, 0 in progress, -1 on fatal error."""
        if SSL_is_init_finished(self.ssl):
            return 1
        cdef int ret = SSL_do_handshake(self.ssl)
        if ret == 1:
            return 1
        cdef int err = SSL_get_error(self.ssl, ret)
        if err == SSL_ERROR_WANT_READ or err == SSL_ERROR_WANT_WRITE:
            return 0
        return -1

    cdef bint handshake_complete(self) noexcept:
        if self.ssl == NULL:
            return False
        return SSL_is_init_finished(self.ssl) != 0

    cdef void handle_timeout(self) noexcept:
        """Handle DTLS retransmission timeout."""
        if self.ssl != NULL:
            SSL_ctrl(self.ssl, DTLS_CTRL_HANDLE_TIMEOUT, 0, NULL)

    def __dealloc__(self):
        if self.ssl != NULL:
            SSL_free(self.ssl)

cdef class DTLSManager:
    """Manages DTLS context and per-address sessions for a Host."""
    cdef SSL_CTX *ctx
    cdef bint is_server
    cdef dict sessions
    cdef object _user_intercept

    def __cinit__(self):
        self.ctx = NULL
        self.sessions = {}
        self._user_intercept = None

    cdef int init_server(self, bytes cert_path, bytes key_path) except -1:
        self.is_server = True
        self.ctx = SSL_CTX_new(DTLS_server_method())
        if self.ctx == NULL:
            raise IOError("Failed to create DTLS server context")

        if SSL_CTX_use_certificate_file(self.ctx, cert_path, SSL_FILETYPE_PEM) != 1:
            SSL_CTX_free(self.ctx)
            self.ctx = NULL
            raise IOError("Failed to load DTLS certificate: " + cert_path.decode())

        if SSL_CTX_use_PrivateKey_file(self.ctx, key_path, SSL_FILETYPE_PEM) != 1:
            SSL_CTX_free(self.ctx)
            self.ctx = NULL
            raise IOError("Failed to load DTLS private key: " + key_path.decode())

        if SSL_CTX_check_private_key(self.ctx) != 1:
            SSL_CTX_free(self.ctx)
            self.ctx = NULL
            raise IOError("DTLS certificate and private key do not match")

        SSL_CTX_set_verify(self.ctx, SSL_VERIFY_NONE, NULL)
        return 0

    cdef int init_client(self) except -1:
        self.is_server = False
        self.ctx = SSL_CTX_new(DTLS_client_method())
        if self.ctx == NULL:
            raise IOError("Failed to create DTLS client context")
        SSL_CTX_set_verify(self.ctx, SSL_VERIFY_NONE, NULL)
        return 0

    cdef DTLSSession get_or_create_session(self, enet_uint32 host, enet_uint16 port):
        cdef tuple key = (host, port)
        cdef DTLSSession session = self.sessions.get(key)
        if session is not None:
            return session
        session = DTLSSession()
        session.init(self.ctx, self.is_server)
        self.sessions[key] = session
        return session

    cdef DTLSSession get_session(self, enet_uint32 host, enet_uint16 port):
        return self.sessions.get((host, port))

    cdef void remove_session(self, enet_uint32 host, enet_uint16 port):
        self.sessions.pop((host, port), None)

    def __dealloc__(self):
        self.sessions = {}
        if self.ctx != NULL:
            SSL_CTX_free(self.ctx)

# Store DTLS managers keyed by host pointer
cdef dict _dtls_managers = {}

cdef int __cdecl dtls_intercept_callback(ENetHost *host, ENetEvent *event) except -1 with gil:
    """C-level intercept callback for DTLS decryption of incoming packets."""
    cdef uintptr_t host_key = <uintptr_t>host
    cdef DTLSManager mgr = <DTLSManager>_dtls_managers.get(host_key)
    if mgr is None:
        return 0

    cdef enet_uint32 addr_host = host.receivedAddress.host
    cdef enet_uint16 addr_port = host.receivedAddress.port
    cdef DTLSSession session = mgr.get_or_create_session(addr_host, addr_port)

    cdef unsigned char out_buf[DTLS_BUF_SIZE]
    cdef unsigned char handshake_buf[DTLS_BUF_SIZE]
    cdef int n, hs_len
    cdef ENetBuffer send_buf

    # Feed the encrypted data into the SSL read BIO
    session.feed_received(host.receivedData, host.receivedDataLength)

    if not session.handshake_complete():
        # Drive the DTLS handshake
        session.do_handshake_step()

        # Flush any handshake response data to the network
        hs_len = session.read_outgoing(handshake_buf, DTLS_BUF_SIZE)
        while hs_len > 0:
            send_buf.data = handshake_buf
            send_buf.dataLength = hs_len
            enet_socket_send(host.socket, &host.receivedAddress, &send_buf, 1)
            hs_len = session.read_outgoing(handshake_buf, DTLS_BUF_SIZE)
        return 1  # suppress ENet processing during handshake

    # Handshake complete: decrypt
    n = session.try_decrypt(out_buf, DTLS_BUF_SIZE)
    if n <= 0:
        # DTLS control message or retransmit
        hs_len = session.read_outgoing(handshake_buf, DTLS_BUF_SIZE)
        while hs_len > 0:
            send_buf.data = handshake_buf
            send_buf.dataLength = hs_len
            enet_socket_send(host.socket, &host.receivedAddress, &send_buf, 1)
            hs_len = session.read_outgoing(handshake_buf, DTLS_BUF_SIZE)
        return 1

    # Replace receivedData with decrypted plaintext
    memcpy(host.packetData[0], out_buf, n)
    host.receivedData = host.packetData[0]
    host.receivedDataLength = n

    # Chain user's intercept callback if set
    if mgr._user_intercept is not None:
        address = Address(None, 0)
        (<Address>address)._enet_address = host.receivedAddress
        ret = mgr._user_intercept(address, (<char*>host.receivedData)[:host.receivedDataLength])
        if ret:
            return 1

    return 0  # let ENet process the decrypted data

cdef int __cdecl dtls_send_callback(ENetHost *host, ENetSocket socket,
                                    const ENetAddress *address,
                                    const ENetBuffer *buffers, size_t bufferCount) noexcept with gil:
    """C-level send callback for DTLS encryption of outgoing packets."""
    cdef uintptr_t host_key = <uintptr_t>host
    cdef unsigned char plaintext[DTLS_BUF_SIZE]
    cdef unsigned char encrypted[DTLS_BUF_SIZE]
    cdef size_t total = 0
    cdef size_t fake_total = 0
    cdef size_t i
    cdef int written
    cdef int enc_len
    cdef ENetBuffer enc_buf

    cdef DTLSManager mgr = <DTLSManager>_dtls_managers.get(host_key)
    if mgr is None:
        return enet_socket_send(socket, address, buffers, bufferCount)

    cdef DTLSSession session = mgr.get_session(address.host, address.port)
    if session is None:
        return enet_socket_send(socket, address, buffers, bufferCount)

    if not session.handshake_complete():
        # DTLS handshake in progress: pretend we sent the data.
        # ENet's reliability layer will retransmit once DTLS is up.
        for i in range(bufferCount):
            fake_total += buffers[i].dataLength
        return <int>fake_total

    # Flatten buffers into contiguous plaintext
    for i in range(bufferCount):
        if total + buffers[i].dataLength > DTLS_BUF_SIZE:
            return -1
        memcpy(plaintext + total, buffers[i].data, buffers[i].dataLength)
        total += buffers[i].dataLength

    # Encrypt through SSL
    written = session.encrypt(plaintext, total)
    if written <= 0:
        return -1

    # Read encrypted output from write BIO
    enc_len = session.read_outgoing(encrypted, DTLS_BUF_SIZE)
    if enc_len <= 0:
        return -1

    # Send encrypted data via raw socket
    enc_buf.data = encrypted
    enc_buf.dataLength = enc_len
    return enet_socket_send(socket, address, &enc_buf, 1)

cdef class Address

cdef class Socket:
    """
    Socket (int socket)

    DESCRIPTION

        An ENet socket.

        Can be used with select and poll.
    """

    cdef ENetSocket _enet_socket

    def send(self, Address address, data):
        cdef ENetBuffer buffer
        if isinstance(data, str):
            data = data.encode()

        buffer.data = <char*>data
        buffer.dataLength = len(data)

        cdef int result = enet_socket_send(self._enet_socket,
            &address._enet_address, &buffer, 1)
        return result

    def fileno(self):
        return self._enet_socket

cdef class Address:
    """
    Address (str address, int port)

    ATTRIBUTES

        str host    Hostname referred to by the Address.
        int port    Port referred to by the Address.

    DESCRIPTION

        An ENet address and port pair.

        When instantiated, performs a resolution upon 'address'. However, if
        'address' is None, enet.HOST_ANY is assumed.
    """

    cdef ENetAddress _enet_address

    def __init__(self, host, port):
        if host is not None:
            # Convert the hostname to a byte string if needed
            self.host = host
        else:
            self.host = None
        self.port = port

    def __str__(self):
        return "{0}:{1}".format(self.host, self.port)

    def __richcmp__(self, obj, op):
        if isinstance(obj, Address):
            if op == 2:
                # This is a '==' operation
                return (obj.host == self.host) and (obj.port == self.port)
            elif op == 3:
                # This is a '!=' operation
                return (obj.host != self.host) or (obj.port != self.port)

        raise NotImplementedError

    @property
    def host(self):
        cdef char host[MAXHOSTNAME]

        if self._enet_address.host == ENET_HOST_ANY:
            return "*"
        elif self._enet_address.host:
            if enet_address_get_host_ip(&self._enet_address, host, MAXHOSTNAME):
                raise IOError("Resolution failure!")
            return host.decode("ascii")

    @host.setter
    def host(self, value):
        if not value or value == "*":
            self._enet_address.host = ENET_HOST_ANY
        else:
            if isinstance(value, str):
                value = value.encode("ascii")
            if enet_address_set_host(&self._enet_address, value):
                raise IOError("Resolution failure!")

    @property
    def hostname(self):
        cdef char host[MAXHOSTNAME]

        if self._enet_address.host == ENET_HOST_ANY:
            return "*"
        elif self._enet_address.host:
            if enet_address_get_host(&self._enet_address, host, MAXHOSTNAME):
                raise IOError("Resolution failure!")
            return host.decode("ascii")

    @property
    def port(self):
        return self._enet_address.port

    @port.setter
    def port(self, value):
        self._enet_address.port = value

cdef void __cdecl _packet_free_callback(ENetPacket* packet) noexcept with gil:
    cdef object func = <object>packet.userData
    func()
    # the packet is about to be destroyed, so decrease the refcount
    Py_DECREF(func)

cdef class Packet:
    """
    Packet (str dataContents, int flags)

    ATTRIBUTES

        str data        Contains the data for the packet.
        int flags       Flags modifying delivery of the Packet:

            enet.PACKET_FLAG_RELIABLE Packet must be received by the target peer
                                      and resend attempts should be made until
                                      the packet is delivered.

            enet.PACKET_FLAG_UNSEQUENCED Packet will not be sequenced with other
                                         packets not supported for reliable
                                         packets.

            enet.PACKET_FLAG_NO_ALLOCATE Packet will not allocate data and user
                                         must supply it instead.

            enet.PACKET_FLAG_UNRELIABLE_FRAGMENT Packet will be fragmented using
                                                 unreliable (instead of reliable)
                                                 sends if it exceeds the MTU...

    DESCRIPTION

        An ENet data packet that may be sent to or received from a peer.

    """

    cdef ENetPacket *_enet_packet
    cdef bint sent

    def __init__(self, data=None, flags=0):
        if data is not None:
            if isinstance(data, str):
                data = data.encode()
            self._enet_packet = enet_packet_create(data, len(data), flags)

        # This will get set to True when a peer.send() is called with the Packet
        # to ensure we don't try to destroy this packet as ENET will handle that
        # for us.
        self.sent = False

    def __dealloc__(self):
        if self.is_valid() and not self.sent:
            enet_packet_destroy(self._enet_packet)

    def is_valid(self):
        if self._enet_packet:
            return True
        else:
            return False

    def set_free_callback(self, func):
        self._enet_packet.freeCallback = _packet_free_callback
        Py_INCREF(func)
        # we're storing a reference, and need to INCREF accordingly
        self._enet_packet.userData = <void*>func

    @property
    def data(self):
        if self.is_valid():
            return (<char *>self._enet_packet.data)[:self._enet_packet.dataLength]
        else:
            raise MemoryError("Packet has not been initiliazed properly!")

    @property
    def dataLength(self):
        if self.is_valid():
            return self._enet_packet.dataLength
        else:
            raise MemoryError("Packet has not been initiliazed properly!")

    @property
    def flags(self):
        if self.is_valid():
            return self._enet_packet.flags
        else:
            raise MemoryError("Packet has not been initiliazed properly!")

    @property
    def sent(self):
        return self.sent

    @sent.setter
    def sent(self, value):
        self.sent = value

cdef class Peer:
    """
    Peer ()

    ATTRIBUTES

        Address address
        int     state       The peer's current state which is one of
                            enet.PEER_STATE_*
        int     packetLoss  Mean packet loss of reliable packets as a ratio with
                            respect to the constant enet.PEER_PACKET_LOSS_SCALE.
        int     packetThrottleAcceleration
        int     packetThrottleDeceleration
        int     packetThrottleInterval
        int     roundTripTime Mean round trip time (RTT), in milliseconds,
                              between sending a reliable packet and receiving
                              its acknowledgement.
        int     incomingPeerID

    DESCRIPTION

        An ENet peer which data packets may be sent or received from.

        This class should never be instantiated directly, but rather via
        enet.Host.connect or enet.Event.Peer.  If you try to access any members
        of a Peer without being properly instantiated from a Host or Event
        object then a MemoryError will be raised.

    """

    cdef ENetPeer *_enet_peer

    def __richcmp__(self, obj, op):
        if isinstance(obj, Peer):
            if op == 2:
                return self.address == obj.address
            elif op == 3:
                return self.address != obj.address
        raise NotImplementedError

    def __hash__(self):
        return <uintptr_t>self._enet_peer

    def send(self, channelID, Packet packet):
        """
        send (int channelID, Packet packet)

        Queues a packet to be sent.

        returns 0 on success, < 0 on failure
        """

        if self.check_valid() and packet.is_valid():
            packet.sent = True
            return enet_peer_send(self._enet_peer, channelID, packet._enet_packet)

    def receive(self, unsigned char channelID):
        """
        receive (int channelID)

        Attempts to dequeue any incoming queued packet.
        """

        if self.check_valid():
            packet = Packet()
            (<Packet> packet)._enet_packet = enet_peer_receive(self._enet_peer, &channelID)

            if packet._enet_packet:
                return packet
            else:
                return None

    def reset(self):
        """
        reset ()

        Forcefully disconnects a peer.
        """

        if self.check_valid():
            enet_peer_reset(self._enet_peer)

    def ping(self):
        """
        ping ()

        Sends a ping request to a peer.
        """

        if self.check_valid():
            enet_peer_ping(self._enet_peer)

    def disconnect(self, data=0):
        """
        disconnect ()

        Request a disconnection from a peer.
        """

        if self.check_valid():
            enet_peer_disconnect(self._enet_peer, data)

    def disconnect_later(self, data=0):
        """
        disconnect_later ()

        Request a disconnection from a peer, but only after all queued outgoing
        packets are sent.
        """

        if self.check_valid():
            enet_peer_disconnect_later(self._enet_peer, data)

    def disconnect_now(self, data=0):
        """
        disconnect_now ()

        Force an immediate disconnection from a peer.
        """

        if self.check_valid():
            enet_peer_disconnect_now(self._enet_peer, data)


    def check_valid(self):
        """
        check_valid ()

        Returns True if there is a valid enet_peer set
        Raises a Memory error if not

        """
        if self._enet_peer:
            return True
        else:
            raise MemoryError("Empty Peer object accessed!")

    @property
    def host(self):
        if self.check_valid():
            # be a bit like pickle here. otherwise Host
            # would create a new enet host inside __init__
            h = Host.__new__(Host)
            (<Host> h)._enet_host = self._enet_peer.host
            return h

    @property
    def outgoingPeerID(self):
        if self.check_valid():
            return self._enet_peer.outgoingPeerID

    @property
    def incomingPeerID(self):
        if self.check_valid():
            return self._enet_peer.incomingPeerID

    @property
    def connectID(self):
        if self.check_valid():
            return self._enet_peer.connectID

    @property
    def outgoingSessionID(self):
        if self.check_valid():
            return self._enet_peer.outgoingSessionID

    @property
    def incomingSessionID(self):
        if self.check_valid():
            return self._enet_peer.incomingSessionID

    @property
    def address(self):
        if self.check_valid():
            a = Address(None, 0)
            (<Address> a)._enet_address = self._enet_peer.address
            return a

    @property
    def data(self):
        if self.check_valid():
            return self._enet_peer.data

    @data.setter
    def data(self, value):
        if self.check_valid():
            if isinstance(value, str):
                value = value.encode()
            self._enet_peer.data = value

    @property
    def state(self):
        if self.check_valid():
            return self._enet_peer.state

    @property
    def channelCount(self):
        if self.check_valid():
            return self._enet_peer.channelCount

    @property
    def incomingBandwidth(self):
        if self.check_valid():
            return self._enet_peer.incomingBandwidth

    @property
    def outgoingBandwidth(self):
        if self.check_valid():
            return self._enet_peer.outgoingBandwidth

    @property
    def incomingBandwidthThrottleEpoch(self):
        if self.check_valid():
            return self._enet_peer.incomingBandwidthThrottleEpoch

    @property
    def outgoingBandwidthThrottleEpoch(self):
        if self.check_valid():
            return self._enet_peer.outgoingBandwidthThrottleEpoch

    @property
    def incomingDataTotal(self):
        if self.check_valid():
            return self._enet_peer.incomingDataTotal

    @property
    def outgoingDataTotal(self):
        if self.check_valid():
            return self._enet_peer.outgoingDataTotal

    @property
    def lastSendTime(self):
        if self.check_valid():
            return self._enet_peer.lastSendTime

    @property
    def lastReceiveTime(self):
        if self.check_valid():
            return self._enet_peer.lastReceiveTime

    @property
    def nextTimeout(self):
        if self.check_valid():
            return self._enet_peer.nextTimeout

    @property
    def earliestTimeout(self):
        if self.check_valid():
            return self._enet_peer.earliestTimeout

    @property
    def packetLossEpoch(self):
        if self.check_valid():
            return self._enet_peer.packetLossEpoch

    @property
    def packetsSent(self):
        if self.check_valid():
            return self._enet_peer.packetsSent

    @property
    def packetsLost(self):
        if self.check_valid():
            return self._enet_peer.packetsLost

    @property
    def packetLoss(self):
        if self.check_valid():
            return self._enet_peer.packetLoss

    @property
    def packetLossVariance(self):
        if self.check_valid():
            return self._enet_peer.packetLossVariance

    @property
    def packetThrottle(self):
        if self.check_valid():
            return self._enet_peer.packetThrottle

    @property
    def packetThrottleLimit(self):
        if self.check_valid():
            return self._enet_peer.packetThrottleLimit

    @property
    def packetThrottleCounter(self):
        if self.check_valid():
            return self._enet_peer.packetThrottleCounter

    @property
    def packetThrottleEpoch(self):
        if self.check_valid():
            return self._enet_peer.packetThrottleEpoch

    @property
    def packetThrottleAcceleration(self):
        if self.check_valid():
            return self._enet_peer.packetThrottleAcceleration

    @packetThrottleAcceleration.setter
    def packetThrottleAcceleration(self, value):
        if self.check_valid():
            enet_peer_throttle_configure(self._enet_peer,
                self.packetThrottleInterval, value,
                self.packetThrottleDeceleration)

    @property
    def packetThrottleDeceleration(self):
        if self.check_valid():
            return self._enet_peer.packetThrottleDeceleration

    @packetThrottleDeceleration.setter
    def packetThrottleDeceleration(self, value):
        if self.check_valid():
            enet_peer_throttle_configure(self._enet_peer,
                self.packetThrottleInterval,
                self.packetThrottleAcceleration, value)

    @property
    def packetThrottleInterval(self):
        if self.check_valid():
            return self._enet_peer.packetThrottleInterval

    @packetThrottleInterval.setter
    def packetThrottleInterval(self, value):
        if self.check_valid():
            enet_peer_throttle_configure(
                self._enet_peer, value, self.packetThrottleAcceleration,
                self.packetThrottleDeceleration)

    @property
    def lastRoundTripTime(self):
        if self.check_valid():
            return self._enet_peer.lastRoundTripTime

    @property
    def lowestRoundTripTime(self):
        if self.check_valid():
            return self._enet_peer.lowestRoundTripTime

    @property
    def lastRoundTripTimeVariance(self):
        if self.check_valid():
            return self._enet_peer.lastRoundTripTimeVariance

    @property
    def highestRoundTripTimeVariance(self):
        if self.check_valid():
            return self._enet_peer.highestRoundTripTimeVariance

    @property
    def roundTripTime(self):
        if self.check_valid():
            return self._enet_peer.roundTripTime

    @property
    def roundTripTimeVariance(self):
        if self.check_valid():
            return self._enet_peer.roundTripTimeVariance

    @property
    def mtu(self):
        if self.check_valid():
            return self._enet_peer.mtu

    @property
    def windowSize(self):
        if self.check_valid():
            return self._enet_peer.windowSize

    @property
    def reliableDataInTransit(self):
        if self.check_valid():
            return self._enet_peer.reliableDataInTransit

    @property
    def outgoingReliableSequenceNumber(self):
        if self.check_valid():
            return self._enet_peer.outgoingReliableSequenceNumber

    @property
    def needsDispatch(self):
        if self.check_valid():
            return int(bool(self._enet_peer.flags & ENET_PEER_FLAG_NEEDS_DISPATCH))

    @property
    def incomingUnsequencedGroup(self):
        if self.check_valid():
            return self._enet_peer.incomingUnsequencedGroup

    @property
    def outgoingUnsequencedGroup(self):
        if self.check_valid():
            return self._enet_peer.outgoingUnsequencedGroup

    @property
    def eventData(self):
        if self.check_valid():
            return self._enet_peer.eventData

cdef class Event:
    """
    Event ()

    ATTRIBUTES

        int     type        Type of the event.  Will be enet.EVENT_TYPE_*.
        Peer    peer        Peer that generated the event.
        int     channelID
        Packet  packet

    DESCRIPTION

        An ENet event as returned by enet.Host.service.

        This class should never be instantiated directly.
    """

    cdef ENetEvent _enet_event
    cdef Packet _packet

    def __init__(self):
        self._packet = None

    @property
    def type(self):
        return self._enet_event.type

    @property
    def peer(self):
        peer = Peer()
        (<Peer> peer)._enet_peer = self._enet_event.peer
        return peer

    @property
    def channelID(self):
        return self._enet_event.channelID

    @property
    def data(self):
        return self._enet_event.data

    @property
    def packet(self):
        if not self._packet:
            self._packet = Packet()
            (<Packet> self._packet)._enet_packet = self._enet_event.packet
        return self._packet

from weakref import WeakValueDictionary
cdef host_static_instances = WeakValueDictionary()

cdef class Host:
    """
    Host (Address address, int peerCount, int channelLimit,
        int incomingBandwidth, int outgoingBandwidth)

    ATTRIBUTES

        Address address             Internet address of the host.
        Socket  socket              The socket the host services.
        int     incomingBandwidth   Downstream bandwidth of the host.
        int     outgoingBandwidth   Upstream bandwidth of the host.

    DESCRIPTION

        An ENet host for communicating with peers.

        If 'address' is None, then the Host will be client only.
    """

    cdef ENetHost *_enet_host
    cdef bint dealloc
    cdef object _interceptCallback
    cdef object __weakref__
    cdef object _dtls_manager

    def __init__ (self, Address address=None, peerCount=0, channelLimit=0,
        incomingBandwidth=0, outgoingBandwidth=0,
        dtls_cert=None, dtls_key=None):

        if address:
            self._enet_host = enet_host_create(&address._enet_address, peerCount, channelLimit, incomingBandwidth, outgoingBandwidth)
        else:
            self._enet_host = enet_host_create(NULL, peerCount, channelLimit, incomingBandwidth, outgoingBandwidth)

        if not self._enet_host:
            raise MemoryError("Unable to create host structure!")
        self.dealloc = True
        self._dtls_manager = None

        global host_static_instances
        host_static_instances[<uintptr_t>self._enet_host] = self

        # Initialize DTLS server mode if cert/key provided
        if dtls_cert is not None and dtls_key is not None:
            self._setup_dtls_server(dtls_cert, dtls_key)

    def __hash__(self):
        return <uintptr_t>self._enet_host

    def __cinit__(self):
        self.dealloc = False
        self._enet_host = NULL
        self._dtls_manager = None

    def __dealloc__(self):
        if self._dtls_manager is not None and self._enet_host != NULL:
            _dtls_managers.pop(<uintptr_t>self._enet_host, None)
            self._dtls_manager = None
        if self.dealloc:
            enet_host_destroy(self._enet_host)

    def connect(self, Address address, channelCount, data=0, dtls=False):
        """
        Peer connect (Address address, int channelCount, int data, bool dtls)

        Initiates a connection to a foreign host and returns a Peer.
        If dtls=True, performs a DTLS handshake before connecting.
        """

        if not self._enet_host:
            return

        if dtls:
            if self._dtls_manager is None:
                self._setup_dtls_client()
            if self._dtls_manager is not None:
                self._dtls_initiate_handshake(address)

        peer = Peer()
        (<Peer> peer)._enet_peer = enet_host_connect(
            self._enet_host, &address._enet_address, channelCount, data)

        if not (<Peer> peer)._enet_peer:
            raise IOError("Connection failure!")

        return peer

    def _dtls_initiate_handshake(self, Address address):
        """Initiate DTLS handshake by sending ClientHello (non-blocking)."""
        cdef DTLSManager mgr = <DTLSManager>self._dtls_manager
        cdef DTLSSession session = mgr.get_or_create_session(
            address._enet_address.host, address._enet_address.port)

        cdef unsigned char buf[DTLS_BUF_SIZE]
        cdef int hs_len
        cdef ENetBuffer send_buf

        # Kick off handshake (generates ClientHello)
        session.do_handshake_step()

        # Send ClientHello to the server
        hs_len = session.read_outgoing(buf, DTLS_BUF_SIZE)
        while hs_len > 0:
            send_buf.data = buf
            send_buf.dataLength = hs_len
            enet_socket_send(self._enet_host.socket,
                &address._enet_address, &send_buf, 1)
            hs_len = session.read_outgoing(buf, DTLS_BUF_SIZE)

    def check_events(self):
        """
        Checks for any queued events on the host and dispatches one if available
        """

        if self._enet_host:
            event = Event()
            result = enet_host_check_events(
                self._enet_host, &(<Event> event)._enet_event)

            if result < 0:
                raise IOError("Servicing error - probably disconnected.")
            elif result == 0:
                return None
            else:
                return event

    def service(self, timeout, fast_drop=False):
        """
        Event service (int timeout)

        Waits for events on the host specified and shuttles packets between
        the host and its peers. The timeout is in milliseconds.

        if fast_drop is set, None can be returned instead
        """

        if self._enet_host:
            event = Event()
            result = enet_host_service(
                self._enet_host, &(<Event> event)._enet_event, timeout)

            if result < 0:
                raise IOError("Servicing error - probably disconnected.")

            # Clean up DTLS session on peer disconnect
            if self._dtls_manager is not None and result > 0:
                if (<Event>event)._enet_event.type == ENET_EVENT_TYPE_DISCONNECT:
                    (<DTLSManager>self._dtls_manager).remove_session(
                        (<Event>event)._enet_event.peer.address.host,
                        (<Event>event)._enet_event.peer.address.port)

            if result == 0 and fast_drop:
                return None
            else:
                return event

    def flush(self):
        """
        flush ()

        Sends any queued packets on the host specified to its designated peers.
        """

        if self._enet_host:
            enet_host_flush(self._enet_host)

    def broadcast(self, channelID, Packet packet):
        """
        broadcast (int channelID, Packet packet)

        Queues a packet to be sent to all peers associated with the host.
        """

        if self._enet_host:
            if packet.is_valid():
                packet.sent = True
                enet_host_broadcast(self._enet_host, channelID, packet._enet_packet)

    def compress_with_range_coder(self):
        """
        Sets the packet compressor the host should use to the default range coder
        """

        if self._enet_host:
            return enet_host_compress_with_range_coder(self._enet_host);

    def _setup_dtls_server(self, cert_path, key_path):
        """Initialize DTLS in server mode with certificate and key files."""
        if isinstance(cert_path, str):
            cert_path = cert_path.encode()
        if isinstance(key_path, str):
            key_path = key_path.encode()
        cdef DTLSManager mgr = DTLSManager()
        mgr.init_server(cert_path, key_path)
        self._dtls_manager = mgr
        _dtls_managers[<uintptr_t>self._enet_host] = mgr
        self._enet_host.intercept = dtls_intercept_callback
        self._enet_host.sendCallback = dtls_send_callback

    def _setup_dtls_client(self):
        """Initialize DTLS in client mode."""
        cdef DTLSManager mgr = DTLSManager()
        mgr.init_client()
        self._dtls_manager = mgr
        _dtls_managers[<uintptr_t>self._enet_host] = mgr
        self._enet_host.intercept = dtls_intercept_callback
        self._enet_host.sendCallback = dtls_send_callback

    @property
    def dtls_enabled(self):
        """True if DTLS is active on this host."""
        return self._dtls_manager is not None

    @property
    def socket(self):
        socket = Socket()
        (<Socket> socket)._enet_socket = self._enet_host.socket
        return socket

    @property
    def address(self):
        if self._enet_host:
            a = Address(None, 0)
            (<Address> a)._enet_address = self._enet_host.address
            return a

    @property
    def incomingBandwidth(self):
        return self._enet_host.incomingBandwidth

    @incomingBandwidth.setter
    def incomingBandwidth(self, value):
        enet_host_bandwidth_limit(self._enet_host,
            value, self.outgoingBandwidth)

    @property
    def outgoingBandwidth(self):
        return self._enet_host.outgoingBandwidth

    @outgoingBandwidth.setter
    def outgoingBandwidth(self, value):
        enet_host_bandwidth_limit(self._enet_host,
            self.incomingBandwidth, value)

    @property
    def peers(self):
        cdef size_t i
        peers = []
        for i in range(self.peerCount):
            peer = Peer()
            (<Peer> peer)._enet_peer = &self._enet_host.peers[i]
            peers.append(peer)
        return peers

    @property
    def peerCount(self):
        return self._enet_host.peerCount

    @property
    def channelLimit(self):
        return self._enet_host.channelLimit

    @channelLimit.setter
    def channelLimit(self, value):
        enet_host_channel_limit(self._enet_host, value)

    @property
    def totalSentData(self):
        return self._enet_host.totalSentData

    @totalSentData.setter
    def totalSentData(self, value):
        self._enet_host.totalSentData = value

    @property
    def totalSentPackets(self):
        return self._enet_host.totalSentPackets

    @totalSentPackets.setter
    def totalSentPackets(self, value):
        self._enet_host.totalSentPackets = value

    @property
    def totalReceivedData(self):
        return self._enet_host.totalReceivedData

    @totalReceivedData.setter
    def totalReceivedData(self, value):
        self._enet_host.totalReceivedData = value

    @property
    def totalReceivedPackets(self):
        return self._enet_host.totalReceivedPackets

    @totalReceivedPackets.setter
    def totalReceivedPackets(self, value):
        self._enet_host.totalReceivedPackets = value

    @property
    def intercept(self):
        return self._interceptCallback

    @intercept.setter
    def intercept(self, value):
        if self._dtls_manager is not None:
            # When DTLS is active, store user callback in the manager
            # and keep the DTLS intercept as the C-level callback
            (<DTLSManager>self._dtls_manager)._user_intercept = value
            self._interceptCallback = value
            return
        if value is None:
            self._enet_host.intercept = NULL
        else:
            self._enet_host.intercept = intercept_callback
        self._interceptCallback = value


cdef int __cdecl intercept_callback(ENetHost *host, ENetEvent *event) except -1:
    cdef Address address = Address(None, 0)
    address._enet_address = host.receivedAddress
    cdef object ret = None

    if <uintptr_t>host in host_static_instances:
        ret = host_static_instances[<uintptr_t>host].intercept(address, (<char*>host.receivedData)[:host.receivedDataLength])
    return int(bool(ret))

def _enet_atexit():
    enet_deinitialize()

enet_initialize()
atexit.register(_enet_atexit)

# Module-level DTLS availability constant
DTLS_AVAILABLE = True
