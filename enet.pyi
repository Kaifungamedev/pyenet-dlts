"""Type stubs for the enet module (pyenet-dtls)."""

from typing import Callable, Optional

# Packet flags
PACKET_FLAG_RELIABLE: int
PACKET_FLAG_UNSEQUENCED: int
PACKET_FLAG_NO_ALLOCATE: int
PACKET_FLAG_UNRELIABLE_FRAGMENT: int

# Event types
EVENT_TYPE_NONE: int
EVENT_TYPE_CONNECT: int
EVENT_TYPE_DISCONNECT: int
EVENT_TYPE_RECEIVE: int

# Peer states
PEER_STATE_DISCONNECTED: int
PEER_STATE_CONNECTING: int
PEER_STATE_ACKNOWLEDGING_CONNECT: int
PEER_STATE_CONNECTION_PENDING: int
PEER_STATE_CONNECTION_SUCCEEDED: int
PEER_STATE_CONNECTED: int
PEER_STATE_DISCONNECT_LATER: int
PEER_STATE_DISCONNECTING: int
PEER_STATE_ACKNOWLEDGING_DISCONNECT: int
PEER_STATE_ZOMBIE: int

# DTLS availability
DTLS_AVAILABLE: bool

class Address:
    """
    An ENet address and port pair.

    When instantiated, performs a resolution upon 'address'. However, if
    'address' is None, enet.HOST_ANY is assumed.
    """

    host: Optional[str]
    """Hostname referred to by the Address."""
    port: int
    """Port referred to by the Address."""
    hostname: str
    """Resolved hostname of the Address."""

    def __init__(self, host: Optional[str], port: int) -> None: ...
    def __str__(self) -> str: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

class Socket:
    """An ENet socket. Can be used with select and poll."""

    def send(self, address: Address, data: bytes | str) -> int: ...
    def fileno(self) -> int: ...

class Packet:
    """
    An ENet data packet that may be sent to or received from a peer.

    Args:
        data: The packet payload.
        flags: Bitwise OR of PACKET_FLAG_* constants.
    """

    data: bytes
    """The packet payload."""
    dataLength: int
    """Length of the packet data in bytes."""
    flags: int
    """Packet flags (PACKET_FLAG_*)."""
    sent: bool
    """Whether the packet has been queued for sending."""

    def __init__(self, data: Optional[bytes | str] = None, flags: int = 0) -> None: ...
    def is_valid(self) -> bool: ...
    def set_free_callback(self, func: Callable[[], None]) -> None: ...

class Peer:
    """
    An ENet peer which data packets may be sent or received from.

    This class should never be instantiated directly, but rather via
    Host.connect or Event.peer.
    """

    host: "Host"
    outgoingPeerID: int
    incomingPeerID: int
    connectID: int
    outgoingSessionID: int
    incomingSessionID: int
    address: Address
    data: bytes
    state: int
    channelCount: int
    incomingBandwidth: int
    outgoingBandwidth: int
    incomingBandwidthThrottleEpoch: int
    outgoingBandwidthThrottleEpoch: int
    incomingDataTotal: int
    outgoingDataTotal: int
    lastSendTime: int
    lastReceiveTime: int
    nextTimeout: int
    earliestTimeout: int
    packetLossEpoch: int
    packetsSent: int
    packetsLost: int
    packetLoss: int
    packetLossVariance: int
    packetThrottle: int
    packetThrottleLimit: int
    packetThrottleCounter: int
    packetThrottleEpoch: int
    packetThrottleAcceleration: int
    packetThrottleDeceleration: int
    packetThrottleInterval: int
    lastRoundTripTime: int
    lowestRoundTripTime: int
    lastRoundTripTimeVariance: int
    highestRoundTripTimeVariance: int
    roundTripTime: int
    """Mean round trip time (RTT) in milliseconds."""
    roundTripTimeVariance: int
    mtu: int
    windowSize: int
    reliableDataInTransit: int
    outgoingReliableSequenceNumber: int
    needsDispatch: int
    incomingUnsequencedGroup: int
    outgoingUnsequencedGroup: int
    eventData: int

    def send(self, channelID: int, packet: Packet) -> int:
        """
        Queues a packet to be sent.

        Returns 0 on success, < 0 on failure.
        """
        ...

    def receive(self, channelID: int) -> Optional[Packet]:
        """Attempts to dequeue any incoming queued packet."""
        ...

    def reset(self) -> None:
        """Forcefully disconnects a peer."""
        ...

    def ping(self) -> None:
        """Sends a ping request to a peer."""
        ...

    def disconnect(self, data: int = 0) -> None:
        """Request a disconnection from a peer."""
        ...

    def disconnect_later(self, data: int = 0) -> None:
        """Request a disconnection from a peer, but only after all queued outgoing packets are sent."""
        ...

    def disconnect_now(self, data: int = 0) -> None:
        """Force an immediate disconnection from a peer."""
        ...

    def check_valid(self) -> bool:
        """Returns True if there is a valid peer. Raises MemoryError if not."""
        ...

class Event:
    """
    An ENet event as returned by Host.service.

    This class should never be instantiated directly.
    """

    type: int
    """Event type (EVENT_TYPE_*)."""
    peer: Peer
    """Peer that generated the event."""
    channelID: int
    """Channel ID for the event."""
    data: int
    """Event data."""
    packet: Packet
    """Packet associated with the event (for EVENT_TYPE_RECEIVE)."""

class Host:
    """
    An ENet host for communicating with peers.

    If 'address' is None, then the Host will be client only.

    Args:
        address: The address to bind to, or None for client-only.
        peerCount: Maximum number of peers.
        channelLimit: Maximum number of channels.
        incomingBandwidth: Downstream bandwidth limit (0 = unlimited).
        outgoingBandwidth: Upstream bandwidth limit (0 = unlimited).
        dtls_cert: Path to DTLS certificate file (PEM). Enables DTLS server mode.
        dtls_key: Path to DTLS private key file (PEM). Required with dtls_cert.
    """

    socket: Socket
    """The socket the host services."""
    address: Address
    """Internet address of the host."""
    incomingBandwidth: int
    """Downstream bandwidth of the host."""
    outgoingBandwidth: int
    """Upstream bandwidth of the host."""
    peers: list[Peer]
    """List of peers associated with the host."""
    peerCount: int
    """Maximum number of peers."""
    channelLimit: int
    """Maximum number of channels allowed."""
    totalSentData: int
    totalSentPackets: int
    totalReceivedData: int
    totalReceivedPackets: int
    intercept: Optional[Callable[[Address, bytes], Optional[int]]]
    """Callback to intercept received raw UDP packets."""
    dtls_enabled: bool
    """True if DTLS is active on this host."""

    def __init__(
        self,
        address: Optional[Address] = None,
        peerCount: int = 0,
        channelLimit: int = 0,
        incomingBandwidth: int = 0,
        outgoingBandwidth: int = 0,
        dtls_cert: Optional[str] = None,
        dtls_key: Optional[str] = None,
    ) -> None: ...

    def connect(self, address: Address, channelCount: int, data: int = 0, dtls: bool = False) -> Peer:
        """
        Initiates a connection to a foreign host and returns a Peer.

        Args:
            address: The address to connect to.
            channelCount: Number of channels to allocate.
            data: User data for the connection.
            dtls: If True, performs a DTLS handshake. Requires DTLS_AVAILABLE.
        """
        ...

    def check_events(self) -> Optional[Event]:
        """Checks for any queued events on the host and dispatches one if available."""
        ...

    def service(self, timeout: int, fast_drop: bool = False) -> Optional[Event]:
        """
        Waits for events on the host and shuttles packets between the host and its peers.

        Args:
            timeout: Timeout in milliseconds.
            fast_drop: If True, returns None instead of an empty Event when no event occurs.
        """
        ...

    def flush(self) -> None:
        """Sends any queued packets on the host to its designated peers."""
        ...

    def broadcast(self, channelID: int, packet: Packet) -> None:
        """Queues a packet to be sent to all peers associated with the host."""
        ...

    def compress_with_range_coder(self) -> int:
        """Sets the packet compressor to the default range coder."""
        ...
