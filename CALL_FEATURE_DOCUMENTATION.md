# In-App WebRTC Voice Call Feature Documentation

## Overview

The SUPER-APP includes a robust **in-app WebRTC voice calling system** that enables real-time voice communication between passengers and drivers during active rides. This eliminates the need for phone number exposure and provides a seamless, privacy-preserving calling experience.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Call Flow](#call-flow)
3. [API Endpoints](#api-endpoints)
4. [WebSocket Messages](#websocket-messages)
5. [Call States](#call-states)
6. [Client Implementation](#client-implementation)
7. [WebRTC Configuration](#webrtc-configuration)
8. [Testing Guide](#testing-guide)
9. [Troubleshooting](#troubleshooting)
10. [Security Considerations](#security-considerations)

---

## Architecture Overview

### Components

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Passenger │◄───────►│    Server    │◄───────►│    Driver   │
│   (Client)  │  HTTPS  │  (Backend)   │  HTTPS  │   (Client)  │
└─────────────┘         └──────────────┘         └─────────────┘
       │                       │                         │
       │    WebSocket          │         WebSocket       │
       │◄─────────────────────►│◄───────────────────────►│
       │                       │                         │
       │         WebRTC (Peer-to-Peer Audio)             │
       │◄───────────────────────────────────────────────►│
```

### Technology Stack

- **Backend**: Go (Gin framework)
- **Real-time Communication**: WebSocket for signaling
- **Voice Transport**: WebRTC (peer-to-peer audio)
- **Database**: PostgreSQL (call session records)
- **STUN/TURN Servers**: Google, Cloudflare, etc.

### Key Features

- ✅ **Privacy-preserving**: No phone number exchange needed
- ✅ **Real-time**: WebRTC peer-to-peer audio streaming
- ✅ **Ride-bound**: Calls only available during active rides
- ✅ **Session tracking**: Complete call history and duration
- ✅ **Bidirectional**: Both passenger and driver can initiate
- ✅ **WebSocket signaling**: Reliable connection establishment

---

## Call Flow

### Complete Call Sequence

```
1. INITIATE PHASE
   Passenger/Driver                    Server                     Driver/Passenger
        │                                │                              │
        │──── POST /rides/:id/call ─────>│                              │
        │                                │                              │
        │<──── session_id + recipient ───│                              │
        │                                │                              │
        │                                │──── WS: call_initiate ──────>│
        │                                │                              │
        │                                │                              │

2. WEBRTC NEGOTIATION PHASE
   Caller                              Server                      Callee
        │                                │                              │
        │──── WS: call_offer (SDP) ─────>│                              │
        │                                │                              │
        │                                │──── WS: call_offer ─────────>│
        │                                │                              │
        │                                │                              │
        │                                │<─── WS: call_answer_sdp ─────│
        │                                │      (POST /answer)          │
        │<─── WS: call_answer_sdp ───────│                              │
        │                                │                              │

3. ICE CANDIDATE EXCHANGE
   Both Peers                          Server                      Both Peers
        │                                │                              │
        │──── WS: call_ice_candidate ───>│                              │
        │                                │                              │
        │                                │──── WS: call_ice_candidate ─>│
        │                                │                              │
        │<─── WS: call_ice_candidate ────│                              │
        │                                │                              │
        │                  [ICE Connection Established]                 │
        │◄────────────── Peer-to-Peer Audio Stream ────────────────────>│
        │                                │                              │

4. ACTIVE CALL
        │                                │                              │
        │◄──────────────── Audio Flowing ──────────────────────────────>│
        │                                │                              │

5. TERMINATION PHASE
        │                                │                              │
        │──── POST /calls/:id/end ──────>│                              │
        │                                │                              │
        │                                │──── WS: call_end ───────────>│
        │                                │                              │
        │                  [Cleanup Peer Connection]                    │
        │                                │                              │
```

---

## API Endpoints

### 1. POST /api/v1/rides/:ride_id/call
**Initiate a voice call for a ride**

**Authentication:** Required (Bearer token)

**URL Parameters:**
- `ride_id` (required): The ID of the active ride

**Conditions:**
- Ride must be in one of these statuses: `accepted`, `arrived`, `started`
- Caller must be either the passenger or driver of the ride
- No existing active call session for this ride

**Request Example:**
```bash
POST /api/v1/rides/123/call
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "session_id": 45,
  "ride_id": 123,
  "recipient_id": 5,
  "recipient_name": "John Doe",
  "recipient_role": "driver",
  "message": "Calling John Doe..."
}
```

**Error Responses:**
```json
// 400 - Invalid ride status
{
  "error": "can only call during active rides"
}

// 400 - Already calling
{
  "error": "there is already an active call for this ride"
}

// 401 - Not authorized
{
  "error": "unauthorized: you must be part of this ride to make a call"
}

// 404 - Ride not found
{
  "error": "ride not found"
}
```

**Side Effects:**
- Creates a new `CallSession` record in database
- Sends WebSocket `call_initiate` message to recipient
- Sets call status to `ringing`

---

### 2. POST /api/v1/calls/:session_id/answer
**Answer an incoming call**

**Authentication:** Required

**URL Parameters:**
- `session_id` (required): The call session ID

**Authorization:**
- Only the call recipient can answer

**Request Example:**
```bash
POST /api/v1/calls/45/answer
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "message": "call answered"
}
```

**Error Responses:**
```json
// 401 - Not the recipient
{
  "error": "unauthorized: you are not the recipient of this call"
}

// 404 - Session not found
{
  "error": "call session not found"
}
```

**Side Effects:**
- Updates call status to `active`
- Sets `started_at` timestamp
- Sends WebSocket `call_answer` message to caller

---

### 3. POST /api/v1/calls/:session_id/reject
**Reject an incoming call**

**Authentication:** Required

**URL Parameters:**
- `session_id` (required): The call session ID

**Authorization:**
- Only the call recipient can reject

**Request Example:**
```bash
POST /api/v1/calls/45/reject
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "message": "call rejected"
}
```

**Error Responses:**
```json
// 401 - Not the recipient
{
  "error": "unauthorized: you are not the recipient of this call"
}

// 404 - Session not found
{
  "error": "call session not found"
}
```

**Side Effects:**
- Updates call status to `rejected`
- Sets `ended_at` timestamp
- Sends WebSocket `call_reject` message to caller

---

### 4. POST /api/v1/calls/:session_id/end
**End an active call**

**Authentication:** Required

**URL Parameters:**
- `session_id` (required): The call session ID

**Request Body:**
```json
{
  "duration": 180
}
```

**Field Details:**
- `duration` (required): Call duration in seconds (integer)

**Authorization:**
- Either caller or recipient can end the call

**Request Example:**
```bash
POST /api/v1/calls/45/end
Authorization: Bearer <token>
Content-Type: application/json

{
  "duration": 180
}
```

**Success Response (200):**
```json
{
  "message": "call session ended",
  "duration": 180
}
```

**Error Responses:**
```json
// 401 - Not part of call
{
  "error": "unauthorized: you are not part of this call"
}

// 404 - Session not found
{
  "error": "call session not found"
}
```

**Side Effects:**
- Updates call status to `completed`
- Records call `duration` in seconds
- Sets `ended_at` timestamp
- Sends WebSocket `call_end` message to other party

---

### 5. GET /api/v1/calls/:session_id
**Get call session details**

**Authentication:** Required

**URL Parameters:**
- `session_id` (required): The call session ID

**Request Example:**
```bash
GET /api/v1/calls/45
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "id": 45,
  "ride_id": 123,
  "passenger_id": 1,
  "driver_id": 5,
  "caller_id": 1,
  "recipient_id": 5,
  "status": "completed",
  "duration": 180,
  "started_at": "2024-01-15T10:30:00Z",
  "ended_at": "2024-01-15T10:33:00Z",
  "created_at": "2024-01-15T10:29:45Z",
  "updated_at": "2024-01-15T10:33:00Z"
}
```

**Error Response:**
```json
// 404 - Not found
{
  "error": "call session not found"
}
```

---

## WebSocket Messages

All WebSocket messages follow this format:

```json
{
  "type": "message_type",
  "data": { /* message-specific data */ },
  "timestamp": "2024-01-15T10:30:00Z",
  "ride_id": 123,
  "user_id": 1
}
```

### Message Types

#### 1. call_initiate
**Sent by**: Server → Recipient
**When**: Caller initiates a call

```json
{
  "type": "call_initiate",
  "data": {
    "session_id": 45,
    "ride_id": 123,
    "caller_id": 1,
    "recipient_id": 5,
    "caller_name": "Jane Smith",
    "message": "Jane Smith is calling you"
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "ride_id": 123,
  "user_id": 1
}
```

**Client Action**: Display incoming call UI, enable answer/reject buttons

---

#### 2. call_answer
**Sent by**: Server → Caller
**When**: Recipient answers the call

```json
{
  "type": "call_answer",
  "data": {
    "session_id": 45,
    "ride_id": 123,
    "recipient_id": 5,
    "message": "Call answered"
  },
  "timestamp": "2024-01-15T10:30:15Z",
  "ride_id": 123
}
```

**Client Action**: Update UI to show call is active

---

#### 3. call_reject
**Sent by**: Server → Caller
**When**: Recipient rejects the call

```json
{
  "type": "call_reject",
  "data": {
    "session_id": 45,
    "ride_id": 123,
    "message": "Call rejected"
  },
  "timestamp": "2024-01-15T10:30:10Z",
  "ride_id": 123
}
```

**Client Action**: Clean up peer connection, show rejection message

---

#### 4. call_end
**Sent by**: Server → Other Party
**When**: Either party ends the call

```json
{
  "type": "call_end",
  "data": {
    "session_id": 45,
    "ride_id": 123,
    "message": "Call ended"
  },
  "timestamp": "2024-01-15T10:33:00Z",
  "ride_id": 123
}
```

**Client Action**: Clean up peer connection, stop audio

---

### WebRTC Signaling Messages

These messages are exchanged between clients via the WebSocket server for WebRTC negotiation:

#### 5. call_offer
**Sent by**: Caller → Server → Callee
**Contains**: WebRTC SDP offer

```json
{
  "type": "call_offer",
  "data": {
    "session_id": 45,
    "ride_id": 123,
    "recipient_id": 5,
    "sdp": "v=0\r\no=- 123456789 2 IN IP4 127.0.0.1\r\n..."
  }
}
```

**Client Action**: Callee receives offer, sets remote description, creates answer

---

#### 6. call_answer_sdp
**Sent by**: Callee → Server → Caller
**Contains**: WebRTC SDP answer

```json
{
  "type": "call_answer_sdp",
  "data": {
    "session_id": 45,
    "ride_id": 123,
    "recipient_id": 1,
    "sdp": "v=0\r\no=- 987654321 2 IN IP4 127.0.0.1\r\n..."
  }
}
```

**Client Action**: Caller receives answer, sets remote description

---

#### 7. call_ice_candidate
**Sent by**: Both Peers → Server → Other Peer
**Contains**: ICE candidate information

```json
{
  "type": "call_ice_candidate",
  "data": {
    "session_id": 45,
    "ride_id": 123,
    "recipient_id": 5,
    "candidate": {
      "candidate": "candidate:1 1 UDP 2130706431 192.168.1.5 54321 typ host",
      "sdpMLineIndex": 0,
      "sdpMid": "0"
    }
  }
}
```

**Client Action**: Add received ICE candidate to peer connection

---

## Call States

### CallStatus Enum

```go
type CallStatus string

const (
    CallStatusInitiated CallStatus = "initiated" // Call being created
    CallStatusRinging   CallStatus = "ringing"   // Recipient notified
    CallStatusActive    CallStatus = "active"    // Call in progress
    CallStatusCompleted CallStatus = "completed" // Ended normally
    CallStatusRejected  CallStatus = "rejected"  // Rejected by recipient
    CallStatusMissed    CallStatus = "missed"    // Not answered
    CallStatusFailed    CallStatus = "failed"    // Technical failure
)
```

### State Transitions

```
initiated → ringing → active → completed
            ringing → rejected
            ringing → missed (timeout)
            *       → failed (error)
```

### Database Schema

```sql
CREATE TABLE call_sessions (
    id SERIAL PRIMARY KEY,
    ride_id INTEGER NOT NULL REFERENCES rides(id),
    passenger_id INTEGER NOT NULL REFERENCES users(id),
    driver_id INTEGER NOT NULL REFERENCES users(id),
    caller_id INTEGER NOT NULL REFERENCES users(id),
    recipient_id INTEGER NOT NULL REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'initiated',
    duration INTEGER DEFAULT 0,
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE INDEX idx_call_sessions_ride_id ON call_sessions(ride_id);
CREATE INDEX idx_call_sessions_status ON call_sessions(status);
```

---

## Client Implementation

### Prerequisites

1. **WebSocket Connection**: Must be established and authenticated
2. **Microphone Permission**: Request `getUserMedia` access
3. **Active Ride**: Must have an active ride (accepted, arrived, or started)

### Basic Implementation Flow

```javascript
// 1. Setup WebSocket connection
const ws = new WebSocket(`wss://api.example.com/ws?token=${token}`);

ws.onmessage = async (event) => {
    const message = JSON.parse(event.data);
    await handleWebSocketMessage(message);
};

// 2. Initiate call
async function initiateCall(rideId) {
    // API call to create session
    const response = await fetch(`/api/v1/rides/${rideId}/call`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
    });

    const session = await response.json();

    // Setup WebRTC
    await setupLocalMedia();
    await createOffer();

    return session;
}

// 3. Setup local media
async function setupLocalMedia() {
    localStream = await navigator.mediaDevices.getUserMedia({
        audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true
        },
        video: false
    });

    createPeerConnection();

    localStream.getTracks().forEach(track => {
        peerConnection.addTrack(track, localStream);
    });
}

// 4. Create peer connection
function createPeerConnection() {
    const config = {
        iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:stun.cloudflare.com:3478' }
        ]
    };

    peerConnection = new RTCPeerConnection(config);

    // Handle ICE candidates
    peerConnection.onicecandidate = (event) => {
        if (event.candidate) {
            sendWebSocketMessage('call_ice_candidate', {
                session_id: sessionId,
                ride_id: rideId,
                recipient_id: recipientId,
                candidate: event.candidate
            });
        }
    };

    // Handle remote audio
    peerConnection.ontrack = (event) => {
        remoteAudio.srcObject = event.streams[0];
    };
}

// 5. Create and send offer
async function createOffer() {
    const offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    sendWebSocketMessage('call_offer', {
        session_id: sessionId,
        ride_id: rideId,
        recipient_id: recipientId,
        sdp: offer.sdp
    });
}

// 6. Handle incoming messages
async function handleWebSocketMessage(message) {
    switch (message.type) {
        case 'call_initiate':
            await handleIncomingCall(message.data);
            break;
        case 'call_offer':
            await handleOffer(message.data);
            break;
        case 'call_answer_sdp':
            await handleAnswer(message.data);
            break;
        case 'call_ice_candidate':
            await handleIceCandidate(message.data);
            break;
        case 'call_end':
            cleanupCall();
            break;
    }
}

// 7. Handle offer (for callee)
async function handleOffer(data) {
    await setupLocalMedia();

    await peerConnection.setRemoteDescription(
        new RTCSessionDescription({ type: 'offer', sdp: data.sdp })
    );

    const answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    sendWebSocketMessage('call_answer_sdp', {
        session_id: data.session_id,
        ride_id: data.ride_id,
        recipient_id: data.caller_id,
        sdp: answer.sdp
    });
}

// 8. Handle answer (for caller)
async function handleAnswer(data) {
    await peerConnection.setRemoteDescription(
        new RTCSessionDescription({ type: 'answer', sdp: data.sdp })
    );
}

// 9. Handle ICE candidate
async function handleIceCandidate(data) {
    const candidate = new RTCIceCandidate(data.candidate);
    await peerConnection.addIceCandidate(candidate);
}

// 10. Answer call
async function answerCall(sessionId) {
    const response = await fetch(`/api/v1/calls/${sessionId}/answer`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
    });
}

// 11. End call
async function endCall(sessionId, duration) {
    await fetch(`/api/v1/calls/${sessionId}/end`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ duration })
    });

    cleanupCall();
}

// 12. Cleanup
function cleanupCall() {
    if (peerConnection) {
        peerConnection.close();
        peerConnection = null;
    }

    if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
        localStream = null;
    }
}
```

---

## WebRTC Configuration

### STUN Servers

The system uses multiple public STUN servers for NAT traversal:

```javascript
const iceServers = {
    iceServers: [
        // Google STUN servers
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },

        // Cloudflare STUN
        { urls: 'stun:stun.cloudflare.com:3478' },

        // Open Relay Project
        { urls: 'stun:openrelay.metered.ca:80' },

        // Numb (Viagenie)
        { urls: 'stun:stun.numb.viagenie.ca:3478' },

        // Symbit
        { urls: 'stun:stun.symbit.com:3478' }
    ]
};
```

### Audio Constraints

Recommended audio settings for clear voice communication:

```javascript
const audioConstraints = {
    audio: {
        echoCancellation: true,      // Remove echo
        noiseSuppression: true,       // Reduce background noise
        autoGainControl: true,        // Normalize volume
        googEchoCancellation: true,   // Google-specific echo cancellation
        googAutoGainControl: true,    // Google-specific gain control
        googNoiseSuppression: true,   // Google-specific noise suppression
        googHighpassFilter: true      // Filter low-frequency noise
    },
    video: false
};
```

### ICE Candidate Types

| Type | Description | Usage |
|------|-------------|-------|
| **host** | Local network address | Direct connection (same network) |
| **srflx** | Server reflexive (STUN) | NAT traversal, most common |
| **relay** | Relayed through TURN | Firewall bypass (requires TURN server) |
| **prflx** | Peer reflexive | Discovered during connectivity checks |

---

## Testing Guide

### Using the Test Client

A complete WebRTC test client is provided at `/test/webrtc-test-client.html`

#### Setup

1. **Start the server**:
   ```bash
   go run main.go
   ```

2. **Open test client in two browser tabs**:
   ```
   Tab 1: http://localhost:3000/test/webrtc-test-client.html
   Tab 2: http://localhost:3000/test/webrtc-test-client.html
   ```

3. **Login as passenger in Tab 1**:
   - Click "Quick Login (Passenger)" or enter credentials
   - Click "Login"

4. **Login as driver in Tab 2**:
   - Click "Quick Login (Driver)" or enter credentials
   - Click "Login"

5. **Connect WebSocket in both tabs**:
   - Click "Connect WebSocket"
   - Verify "✅ Connected" status

6. **Create a ride** (using API or admin panel):
   - Ensure ride status is `accepted`, `arrived`, or `started`
   - Note the `ride_id`

7. **Initiate call in Tab 1 (Passenger)**:
   - Enter the `ride_id`
   - Click "📞 Initiate Call"
   - Allow microphone access
   - Wait for driver to answer

8. **Answer call in Tab 2 (Driver)**:
   - Click "✅ Answer Call"
   - Allow microphone access
   - Speak and verify audio is working

9. **End call**:
   - Click "📵 End Call" in either tab

#### Test Scenarios

**Scenario 1: Happy Path**
- ✅ Passenger initiates call
- ✅ Driver answers
- ✅ Audio flows both directions
- ✅ Either party can end call

**Scenario 2: Call Rejection**
- ✅ Passenger initiates call
- ✅ Driver rejects
- ✅ Caller receives rejection notification

**Scenario 3: Multiple ICE Candidates**
- ✅ Both clients behind NAT
- ✅ STUN servers used for traversal
- ✅ Connection established via srflx candidates

**Scenario 4: Network Issues**
- ✅ Temporary disconnection
- ✅ ICE restart mechanism
- ✅ Graceful degradation

---

## Troubleshooting

### Common Issues

#### 1. Microphone Permission Denied

**Symptom**: "Error accessing microphone: Permission denied"

**Solution**:
```javascript
// Check permission status
const permission = await navigator.permissions.query({ name: 'microphone' });
console.log('Microphone permission:', permission.state);

// Request permission explicitly
try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    console.log('✅ Microphone access granted');
} catch (error) {
    console.error('❌ Microphone access denied:', error);
}
```

**Browser Settings**:
- Chrome: `chrome://settings/content/microphone`
- Firefox: Permissions in address bar
- Safari: Preferences → Websites → Microphone

---

#### 2. No Audio Flowing

**Symptom**: Call connects but no audio heard

**Diagnostics**:
```javascript
// Check if tracks are enabled
localStream.getAudioTracks().forEach(track => {
    console.log('Local track:', track.label, 'enabled:', track.enabled);
});

remoteStream.getAudioTracks().forEach(track => {
    console.log('Remote track:', track.label, 'muted:', track.muted);
});

// Check audio element
const remoteAudio = document.getElementById('remoteAudio');
console.log('Remote audio muted:', remoteAudio.muted);
console.log('Remote audio volume:', remoteAudio.volume);

// Verify peer connection state
console.log('ICE state:', peerConnection.iceConnectionState);
console.log('Connection state:', peerConnection.connectionState);
```

**Solutions**:
1. Ensure `remoteAudio.autoplay = true`
2. Check that audio element is not muted
3. Verify volume is > 0
4. Check browser autoplay policies

---

#### 3. ICE Connection Failed

**Symptom**: "ICE connection state: failed"

**Possible Causes**:
- STUN servers unreachable
- Symmetric NAT (both users)
- Firewall blocking UDP traffic
- Both users behind strict corporate firewalls

**Solutions**:

1. **Check STUN server connectivity**:
   ```bash
   # Test STUN server
   stunclient stun.l.google.com 19302
   ```

2. **Add TURN server** (for strict NAT):
   ```javascript
   const config = {
       iceServers: [
           { urls: 'stun:stun.l.google.com:19302' },
           {
               urls: 'turn:turn.example.com:3478',
               username: 'user',
               credential: 'pass'
           }
       ]
   };
   ```

3. **Check firewall rules**:
   - Allow UDP ports 3478, 19302
   - Allow UDP port range for WebRTC (49152-65535)

---

#### 4. WebSocket Disconnection During Call

**Symptom**: WebSocket closes unexpectedly during call

**Impact**:
- Existing peer connection continues (direct P2P)
- Cannot send new ICE candidates
- Cannot receive call end notification

**Solution**:
```javascript
ws.onclose = (event) => {
    console.log('WebSocket closed:', event.code, event.reason);

    // Reconnect if during active call
    if (currentCallSession && currentCallSession.status === 'active') {
        console.log('Reconnecting WebSocket...');
        setTimeout(() => {
            connectWebSocket();
        }, 2000);
    }
};
```

---

#### 5. Echo or Feedback

**Symptom**: Hearing your own voice or feedback loop

**Causes**:
- Local audio not muted
- Speaker too close to microphone
- Echo cancellation disabled

**Solutions**:

1. **Mute local audio element**:
   ```javascript
   const localAudio = document.getElementById('localAudio');
   localAudio.muted = true; // Always mute local audio
   ```

2. **Enable echo cancellation**:
   ```javascript
   const stream = await navigator.mediaDevices.getUserMedia({
       audio: {
           echoCancellation: true,
           autoGainControl: true,
           noiseSuppression: true
       }
   });
   ```

3. **Use headphones** instead of speakers

---

#### 6. Call Not Received

**Symptom**: Caller sees "calling" but recipient doesn't receive notification

**Diagnostics**:
```javascript
// Check WebSocket connection
console.log('WS connected:', ws.readyState === WebSocket.OPEN);

// Check if user is authenticated
console.log('User ID:', currentUserId);

// Verify server logs
// Server should log: "Call initiated by X to Y"
```

**Solutions**:
1. Ensure both users have active WebSocket connections
2. Verify authentication tokens are valid
3. Check server logs for message routing
4. Confirm `recipient_id` matches connected user

---

### Debug Tools

#### Browser DevTools

**Chrome**:
1. Open DevTools (F12)
2. Navigate to: `chrome://webrtc-internals`
3. View real-time WebRTC stats

**Firefox**:
1. Open DevTools (F12)
2. Navigate to: `about:webrtc`
3. View connection statistics

#### Client-Side Diagnostics

Use the built-in diagnostic function in test client:

```javascript
function diagnoseConnection() {
    console.log('=== CONNECTION DIAGNOSTICS ===');
    console.log('Peer connection state:', peerConnection.connectionState);
    console.log('ICE connection state:', peerConnection.iceConnectionState);
    console.log('ICE gathering state:', peerConnection.iceGatheringState);

    // Get WebRTC statistics
    peerConnection.getStats().then(stats => {
        stats.forEach(stat => {
            if (stat.type === 'inbound-rtp' && stat.kind === 'audio') {
                console.log('Inbound audio packets:', stat.packetsReceived);
            }
            if (stat.type === 'outbound-rtp' && stat.kind === 'audio') {
                console.log('Outbound audio packets:', stat.packetsSent);
            }
        });
    });
}
```

---

## Security Considerations

### Authentication & Authorization

1. **JWT Token Required**: All API endpoints require valid Bearer token
2. **Ride Membership Verification**: Only ride participants can initiate calls
3. **Session Ownership**: Only call participants can answer/reject/end
4. **WebSocket Authentication**: Token validated on WebSocket connection

### Privacy

1. **No Phone Number Exposure**: Calls use in-app system
2. **Ride-Bound**: Calls only available during active rides
3. **Session Cleanup**: Call records maintained for support/billing
4. **Peer-to-Peer**: Audio never passes through server (direct WebRTC)

### Rate Limiting

Recommended limits:

```go
// Per user
MaxCallsPerHour = 20
MaxActiveCalls = 1

// Per ride
MaxCallSessionsPerRide = 10
```

### WebSocket Security

1. **Token Validation**: Verify JWT on connection
2. **Message Routing**: Only send messages to intended recipients
3. **Signature Verification**: Validate WebRTC signaling messages
4. **Connection Limits**: Prevent WebSocket flooding

### WebRTC Security

1. **DTLS Encryption**: All WebRTC audio encrypted by default
2. **SRTP**: Secure Real-time Transport Protocol for media
3. **ICE Consent**: Both parties must consent to connection
4. **No Relay Required**: Direct P2P connections preferred

---

## Performance Considerations

### Bandwidth Requirements

- **Audio Codec**: Opus (default)
- **Bitrate**: 24-32 kbps (voice optimized)
- **Recommended**: Minimum 50 kbps upload/download

### Latency

- **Target**: < 150ms end-to-end
- **WebSocket**: < 50ms for signaling
- **WebRTC**: < 100ms for audio (P2P)

### Scalability

- **WebSocket Connections**: 10,000+ per server instance
- **Concurrent Calls**: Limited by network, not server CPU
- **STUN Server Load**: Minimal (only for ICE)

### Battery Optimization

```javascript
// Stop tracks when call ends
function cleanupCall() {
    if (localStream) {
        localStream.getTracks().forEach(track => {
            track.stop(); // Important for battery life
        });
    }
}
```

---

## Production Deployment Checklist

- [ ] Configure TURN server for enterprise NAT
- [ ] Setup monitoring for call quality metrics
- [ ] Implement call recording (if required by regulations)
- [ ] Add call timeout mechanism (auto-end after X minutes)
- [ ] Setup analytics for failed calls
- [ ] Test with various network conditions
- [ ] Configure firewall rules for WebRTC ports
- [ ] Setup CDN for STUN/TURN servers globally
- [ ] Implement reconnection logic for network drops
- [ ] Add user feedback mechanism for call quality
- [ ] Setup alerts for high failure rates
- [ ] Test compatibility across browsers/devices

---

## Frequently Asked Questions

### Q: Can calls work without internet?
**A:** No, WebRTC requires internet connectivity for signaling and media transport.

### Q: Are calls recorded?
**A:** No, calls are peer-to-peer and not recorded by default. Can be added if needed.

### Q: What happens if WebSocket disconnects during a call?
**A:** The audio connection continues (P2P), but signaling is interrupted. Implement reconnection logic.

### Q: Can more than 2 people join a call?
**A:** No, the current implementation is 1-to-1 (passenger ↔ driver only).

### Q: What codecs are used?
**A:** Default is Opus for audio (excellent voice quality at low bitrate).

### Q: Do I need a TURN server?
**A:** Not for most cases. STUN is sufficient for ~80% of connections. TURN needed for strict corporate NATs.

### Q: How much data does a 5-minute call use?
**A:** Approximately 6-10 MB (at 24 kbps bitrate).

---

## Support & Resources

### Documentation
- WebRTC Specification: https://www.w3.org/TR/webrtc/
- MDN WebRTC Guide: https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API

### Test Tools
- WebRTC Test Client: `/test/webrtc-test-client.html`
- Chrome WebRTC Internals: `chrome://webrtc-internals`
- Firefox WebRTC Stats: `about:webrtc`

### STUN/TURN Providers
- Twilio: https://www.twilio.com/stun-turn
- Xirsys: https://xirsys.com
- Metered: https://www.metered.ca/tools/openrelay/

---

## Changelog

### v1.0.0 (Initial Release)
- ✅ Basic 1-to-1 voice calling
- ✅ WebSocket signaling
- ✅ WebRTC peer-to-peer audio
- ✅ Call session tracking
- ✅ Multiple STUN server support
- ✅ Test client for development

### Future Enhancements
- [ ] Call quality metrics
- [ ] Automatic call timeout
- [ ] Call recording (compliance)
- [ ] Group calls (3+ participants)
- [ ] Screen sharing
- [ ] Call transfer
- [ ] Voicemail
